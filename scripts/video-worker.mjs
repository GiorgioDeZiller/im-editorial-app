// Worker autonomo: genera i video in coda su Supabase.
// Pipeline: HeyGen (avatar) -> Pexels (immagini) -> Shotstack (montaggio).
// Gira su GitHub Actions (Node 20+, fetch globale). Nessun PC acceso richiesto.

const {
  SUPABASE_URL,
  SUPABASE_KEY,
  HEYGEN_KEY,
  PEXELS_KEY,
  SHOTSTACK_KEY,
  SHOTSTACK_SANDBOX = 'true',
} = process.env;

const sandbox = SHOTSTACK_SANDBOX !== 'false';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const sbHeaders = {
  apikey: SUPABASE_KEY,
  Authorization: `Bearer ${SUPABASE_KEY}`,
  'Content-Type': 'application/json',
};

async function sbGetQueued() {
  const r = await fetch(
    `${SUPABASE_URL}/rest/v1/proposte?video_status=eq.queued&select=*&limit=3`,
    { headers: sbHeaders }
  );
  if (!r.ok) throw new Error(`Supabase get ${r.status}: ${await r.text()}`);
  return r.json();
}

async function sbPatch(id, fields) {
  const r = await fetch(
    `${SUPABASE_URL}/rest/v1/proposte?id=eq.${encodeURIComponent(id)}`,
    { method: 'PATCH', headers: { ...sbHeaders, Prefer: 'return=minimal' }, body: JSON.stringify(fields) }
  );
  if (!r.ok) throw new Error(`Supabase patch ${r.status}: ${await r.text()}`);
}

// ── HeyGen ─────────────────────────────────────────────────────────
async function heygenGenerate(avatarId, voiceId, script) {
  const r = await fetch('https://api.heygen.com/v3/videos', {
    method: 'POST',
    headers: { 'X-Api-Key': HEYGEN_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      type: 'avatar', avatar_id: avatarId, script, voice_id: voiceId,
      aspect_ratio: '9:16', resolution: '720p',
    }),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`HeyGen gen ${r.status}: ${JSON.stringify(j)}`);
  const id = j?.data?.video_id;
  if (!id) throw new Error('HeyGen: nessun video_id');
  return id;
}

async function heygenWait(videoId) {
  for (let i = 0; i < 60; i++) {
    await sleep(8000);
    const r = await fetch(`https://api.heygen.com/v3/videos/${videoId}`, {
      headers: { 'X-Api-Key': HEYGEN_KEY },
    });
    const j = await r.json();
    const d = j?.data || {};
    if (d.status === 'completed') {
      return { url: d.video_url, duration: Number(d.duration) || 40 };
    }
    if (d.status === 'failed') {
      throw new Error(`HeyGen failed: ${d.failure_message || ''}`);
    }
  }
  throw new Error('HeyGen timeout');
}

// ── Pexels ─────────────────────────────────────────────────────────
async function pexelsSearch(query, count) {
  const r = await fetch(
    `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=${count}&orientation=portrait`,
    { headers: { Authorization: PEXELS_KEY } }
  );
  if (!r.ok) return [];
  const j = await r.json();
  return (j.photos || []).map((p) => p?.src?.portrait || p?.src?.large).filter(Boolean);
}

async function pexelsBest(keywords, count) {
  const pools = [];
  for (const kw of keywords) {
    const urls = await pexelsSearch(kw, 6);
    if (urls.length) pools.push(urls);
  }
  const out = [];
  for (let depth = 0; depth < 6 && out.length < count; depth++) {
    for (const pool of pools) {
      if (depth < pool.length && out.length < count && !out.includes(pool[depth])) {
        out.push(pool[depth]);
      }
    }
  }
  return out;
}

// ── Shotstack ──────────────────────────────────────────────────────
const shotstackBase = () =>
  sandbox ? 'https://api.shotstack.io/edit/stage' : 'https://api.shotstack.io/edit/v1';

async function shotstackRender(videoUrl, duration, images) {
  const n = images.length;
  const overlays = [];
  if (n > 0 && duration > 8) {
    const startWindow = 4, endWindow = duration - 2, span = endWindow - startWindow;
    const gap = span / (n + 1);
    let imgLen = Math.min(6, Math.max(2.5, duration / 14));
    if (imgLen > gap * 0.85) imgLen = gap * 0.85;
    for (let i = 0; i < n; i++) {
      let t = startWindow + (span * (i + 1)) / (n + 1) - imgLen / 2;
      if (t < 0) t = 0;
      if (t + imgLen > duration) t = duration - imgLen;
      overlays.push({
        asset: { type: 'image', src: images[i] },
        start: Number(t.toFixed(2)), length: Number(imgLen.toFixed(2)),
        fit: 'cover', transition: { in: 'fade', out: 'fade' },
      });
    }
  }
  const body = {
    timeline: {
      background: '#000000',
      tracks: [
        { clips: overlays },
        { clips: [{ asset: { type: 'video', src: videoUrl }, start: 0, length: Number(duration.toFixed(2)) }] },
      ],
    },
    output: { format: 'mp4', size: { width: 720, height: 1280 } },
  };
  const r = await fetch(`${shotstackBase()}/render`, {
    method: 'POST',
    headers: { 'x-api-key': SHOTSTACK_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`Shotstack render ${r.status}: ${JSON.stringify(j)}`);
  const id = j?.response?.id;
  if (!id) throw new Error('Shotstack: nessun render id');
  return id;
}

async function shotstackWait(renderId) {
  for (let i = 0; i < 60; i++) {
    await sleep(8000);
    const r = await fetch(`${shotstackBase()}/render/${renderId}`, {
      headers: { 'x-api-key': SHOTSTACK_KEY },
    });
    const j = await r.json();
    const s = j?.response || {};
    if (s.status === 'done') return s.url;
    if (s.status === 'failed') throw new Error(`Shotstack failed: ${s.error || ''}`);
  }
  throw new Error('Shotstack timeout');
}

// ── Storage permanente (Supabase Storage) ──────────────────────────
// I link di HeyGen/Shotstack scadono dopo poco: salviamo il file finale
// nel bucket "videos" così il link resta valido per sempre.
async function uploadToStorage(id, sourceUrl) {
  const res = await fetch(sourceUrl);
  if (!res.ok) throw new Error(`download del video finale ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  const name = `${id}-${Date.now()}.mp4`;
  const up = await fetch(`${SUPABASE_URL}/storage/v1/object/videos/${name}`, {
    method: 'POST',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'video/mp4',
      'x-upsert': 'true',
    },
    body: buf,
  });
  if (!up.ok) {
    throw new Error(`upload storage ${up.status}: ${await up.text()}`);
  }
  return `${SUPABASE_URL}/storage/v1/object/public/videos/${name}`;
}

// ── Elaborazione di una riga ───────────────────────────────────────
async function processOne(row) {
  console.log(`Processo ${row.id}...`);
  await sbPatch(row.id, { video_status: 'rendering', video_error: null });
  try {
    const script = (row.video_script || '').trim();
    if (!script) throw new Error('script vuoto');
    const avatarId = row.video_avatar_id;
    const voiceId = row.video_voice_id;
    if (!avatarId || !voiceId) throw new Error('avatar/voce mancanti nella riga');

    const vid = await heygenGenerate(avatarId, voiceId, script);
    const { url: avatarUrl, duration } = await heygenWait(vid);

    let finalUrl = avatarUrl;
    const keywords = (row.video_keywords || '')
      .split(/[,\n]/).map((s) => s.trim()).filter(Boolean);
    const count = Math.min(6, Math.max(2, Math.round(duration / 12)));
    if (keywords.length && PEXELS_KEY && SHOTSTACK_KEY) {
      const images = await pexelsBest(keywords, count);
      if (images.length) {
        const rid = await shotstackRender(avatarUrl, duration, images);
        finalUrl = await shotstackWait(rid);
      }
    }

    // Salva su storage permanente (con fallback al link temporaneo)
    let permanentUrl = finalUrl;
    try {
      permanentUrl = await uploadToStorage(row.id, finalUrl);
      console.log(`  salvato su storage permanente: ${permanentUrl}`);
    } catch (e) {
      console.error(
        `  ATTENZIONE: storage fallito, uso il link temporaneo (${e.message})`
      );
    }

    await sbPatch(row.id, { video_status: 'ready', video_url: permanentUrl });
    console.log(`  OK -> ${permanentUrl}`);
  } catch (e) {
    console.error(`  ERRORE ${row.id}: ${e.message}`);
    await sbPatch(row.id, {
      video_status: 'error',
      video_error: String(e.message).slice(0, 500),
    });
  }
}

(async () => {
  if (!SUPABASE_URL || !SUPABASE_KEY) throw new Error('SUPABASE_URL/KEY mancanti');
  const rows = await sbGetQueued();
  console.log(`Video in coda: ${rows.length}`);
  for (const row of rows) await processOne(row);
  console.log('Fatto.');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
