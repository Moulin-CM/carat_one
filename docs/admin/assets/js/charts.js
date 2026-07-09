// =============================================================
// Carat One — Admin: tiny dependency-free SVG charts
// Not as featureful as Chart.js but keeps the panel light and
// blends with the site's aesthetic.
// =============================================================

/**
 * Render an area+line chart into an SVG element.
 * @param {SVGElement|string} target — element or selector
 * @param {{label:string, value:number}[]} data
 * @param {Object} [opts]
 */
export function lineChart(target, data, opts = {}) {
    const svg = typeof target === 'string' ? document.querySelector(target) : target;
    if (!svg || !data || !data.length) return;
    const w = svg.clientWidth || 640;
    const h = svg.clientHeight || 240;
    const padL = 42, padR = 14, padT = 18, padB = 30;
    const iw = w - padL - padR, ih = h - padT - padB;
    const values = data.map(d => Number(d.value) || 0);
    const max = Math.max(...values, 1);
    const min = Math.min(...values, 0);
    const range = max - min || 1;
    const stroke = opts.stroke || '#38bdf8';
    const fillTop = opts.fillTop || 'rgba(56,189,248,0.35)';
    const fillBot = opts.fillBot || 'rgba(56,189,248,0.02)';
    const stepX = data.length > 1 ? iw / (data.length - 1) : iw;

    const pts = data.map((d, i) => {
        const x = padL + stepX * i;
        const y = padT + ih - ((Number(d.value) - min) / range) * ih;
        return { x, y, d };
    });
    const linePath = pts.map((p, i) => `${i ? 'L' : 'M'}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ');
    const areaPath = `${linePath} L${pts[pts.length - 1].x.toFixed(1)},${padT + ih} L${pts[0].x.toFixed(1)},${padT + ih} Z`;

    // 4 horizontal gridlines
    const gridY = [0, 0.25, 0.5, 0.75, 1].map(t => padT + ih * t);
    const grid = gridY.map(y =>
        `<line x1="${padL}" x2="${w - padR}" y1="${y}" y2="${y}" stroke="rgba(255,255,255,0.06)" stroke-width="1"/>`).join('');
    const yTicks = [0, 0.5, 1].map(t => {
        const v = max - (max - min) * t;
        return `<text x="${padL - 8}" y="${padT + ih * t + 4}" fill="rgba(255,255,255,0.5)" font-size="10" text-anchor="end" font-family="Plus Jakarta Sans">${formatTick(v)}</text>`;
    }).join('');
    const xTicks = pts.map((p, i) => {
        if (data.length > 12 && i % Math.ceil(data.length / 8) !== 0) return '';
        return `<text x="${p.x}" y="${h - 10}" fill="rgba(255,255,255,0.5)" font-size="10" text-anchor="middle" font-family="Plus Jakarta Sans">${p.d.label}</text>`;
    }).join('');
    const dots = pts.map(p =>
        `<circle cx="${p.x}" cy="${p.y}" r="3" fill="${stroke}" stroke="#07091c" stroke-width="2"/>`).join('');

    const gradId = 'g' + Math.random().toString(36).slice(2, 8);
    svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
    svg.setAttribute('preserveAspectRatio', 'none');
    svg.innerHTML = `
        <defs>
            <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%"  stop-color="${fillTop}"/>
                <stop offset="100%" stop-color="${fillBot}"/>
            </linearGradient>
        </defs>
        ${grid}
        ${yTicks}
        <path d="${areaPath}" fill="url(#${gradId})"/>
        <path d="${linePath}" fill="none" stroke="${stroke}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
        ${dots}
        ${xTicks}`;
}

/**
 * Render a simple vertical bar chart.
 */
export function barChart(target, data, opts = {}) {
    const svg = typeof target === 'string' ? document.querySelector(target) : target;
    if (!svg || !data || !data.length) return;
    const w = svg.clientWidth || 640;
    const h = svg.clientHeight || 240;
    const padL = 42, padR = 14, padT = 18, padB = 30;
    const iw = w - padL - padR, ih = h - padT - padB;
    const values = data.map(d => Number(d.value) || 0);
    const max = Math.max(...values, 1);
    const stepX = iw / data.length;
    const bw = Math.max(6, stepX * 0.55);
    const stroke = opts.stroke || '#a78bfa';
    const fillTop = opts.fillTop || 'rgba(167,139,250,0.9)';
    const fillBot = opts.fillBot || 'rgba(167,139,250,0.15)';
    const gradId = 'g' + Math.random().toString(36).slice(2, 8);

    const gridY = [0, 0.25, 0.5, 0.75, 1].map(t => padT + ih * t);
    const grid = gridY.map(y =>
        `<line x1="${padL}" x2="${w - padR}" y1="${y}" y2="${y}" stroke="rgba(255,255,255,0.06)" stroke-width="1"/>`).join('');
    const yTicks = [0, 0.5, 1].map(t => {
        const v = max * (1 - t);
        return `<text x="${padL - 8}" y="${padT + ih * t + 4}" fill="rgba(255,255,255,0.5)" font-size="10" text-anchor="end" font-family="Plus Jakarta Sans">${formatTick(v)}</text>`;
    }).join('');
    const bars = data.map((d, i) => {
        const bh = ((Number(d.value) || 0) / max) * ih;
        const x = padL + stepX * i + (stepX - bw) / 2;
        const y = padT + ih - bh;
        return `<rect x="${x}" y="${y}" width="${bw}" height="${bh}"
                    fill="url(#${gradId})" stroke="${stroke}" stroke-width="1" rx="4"/>`;
    }).join('');
    const xTicks = data.map((d, i) => {
        const x = padL + stepX * i + stepX / 2;
        if (data.length > 12 && i % Math.ceil(data.length / 8) !== 0) return '';
        return `<text x="${x}" y="${h - 10}" fill="rgba(255,255,255,0.5)" font-size="10" text-anchor="middle" font-family="Plus Jakarta Sans">${d.label}</text>`;
    }).join('');

    svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
    svg.innerHTML = `
        <defs>
            <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%"  stop-color="${fillTop}"/>
                <stop offset="100%" stop-color="${fillBot}"/>
            </linearGradient>
        </defs>
        ${grid}
        ${yTicks}
        ${bars}
        ${xTicks}`;
}

/** Render a small horizontal sparkline as a fixed-height <svg>. */
export function sparkline(target, values, opts = {}) {
    const svg = typeof target === 'string' ? document.querySelector(target) : target;
    if (!svg || !values || !values.length) return;
    const w = 120, h = 34;
    const max = Math.max(...values, 1);
    const min = Math.min(...values, 0);
    const range = max - min || 1;
    const stepX = values.length > 1 ? w / (values.length - 1) : w;
    const pts = values.map((v, i) => {
        const x = i * stepX;
        const y = h - ((v - min) / range) * (h - 4) - 2;
        return `${i ? 'L' : 'M'}${x.toFixed(1)},${y.toFixed(1)}`;
    }).join(' ');
    svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
    svg.setAttribute('preserveAspectRatio', 'none');
    svg.innerHTML = `<path d="${pts}" fill="none" stroke="${opts.stroke || '#38bdf8'}" stroke-width="2" stroke-linecap="round"/>`;
}

function formatTick(n) {
    const a = Math.abs(n);
    if (a >= 1e6) return (n / 1e6).toFixed(1) + 'M';
    if (a >= 1e3) return (n / 1e3).toFixed(1) + 'K';
    return Math.round(n).toString();
}
