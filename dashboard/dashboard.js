const tabs   = document.querySelectorAll('.tab');
const panels = document.querySelectorAll('.panel');
let   charts = {};

function switchTab(i) {
  tabs.forEach((t, idx) => t.classList.toggle('active', idx === i));
  panels.forEach((p, idx) => p.classList.toggle('active', idx === i));
  setTimeout(() => renderCharts(i), 50);
}

const cfg = {
  font: "'Sora', sans-serif",
  grid: 'rgba(31,33,48,0.8)',
  tick: '#5A6070',
};

function destroy(id) {
  if (charts[id]) { charts[id].destroy(); delete charts[id]; }
}

function renderCharts(panel) {

  if (panel === 0) {
    destroy('chartTarget');
    destroy('chartDelay');

    charts['chartTarget'] = new Chart(document.getElementById('chartTarget'), {
      type: 'doughnut',
      data: {
        labels: ['Repaid (88%)', 'Default (12%)'],
        datasets: [{ data: [88, 12], backgroundColor: ['#00E676', '#FF4560'], borderWidth: 0 }]
      },
      options: {
        cutout: '68%', responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'right', labels: { color: '#8890A0', font: { family: cfg.font, size: 11 }, padding: 16 } } }
      }
    });

    charts['chartDelay'] = new Chart(document.getElementById('chartDelay'), {
      type: 'bar',
      data: {
        labels: ['0–7d', '8–14d', '15–21d', '22–28d', '29d+'],
        datasets: [{ data: [4200, 980, 620, 310, 890], backgroundColor: ['#00E676', '#00E5FF', '#FFB300', '#845EF7', '#FF4560'], borderRadius: 4, borderSkipped: false }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { color: cfg.grid } },
          y: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { color: cfg.grid } }
        }
      }
    });
  }

  if (panel === 1) {
    destroy('chartLeaderboard');

    charts['chartLeaderboard'] = new Chart(document.getElementById('chartLeaderboard'), {
      type: 'bar',
      data: {
        labels: ['XGBoost', 'LightGBM', 'Linear Learner', 'Neural Net', 'Baseline'],
        datasets: [{ data: [0.934, 0.929, 0.911, 0.908, 0.874], backgroundColor: ['#00E676', '#00E5FF', '#00E5FF', '#845EF7', '#FF4560'], borderRadius: 4, borderSkipped: false }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { display: false } },
          y: { min: 0.85, max: 0.95, ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { color: cfg.grid } }
        }
      }
    });
  }

  if (panel === 2) {
    destroy('chartTrend');

    charts['chartTrend'] = new Chart(document.getElementById('chartTrend'), {
      type: 'line',
      data: {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        datasets: [
          { label: 'Baseline',  data: [88.0, 87.8, 88.2, 87.9, 88.1, 88.0], borderColor: '#FF4560', backgroundColor: 'rgba(255,69,96,0.08)',  tension: 0.4, borderWidth: 2,   pointRadius: 4, fill: true },
          { label: 'Autopilot', data: [91.2, 91.5, 91.8, 92.1, 92.3, 92.4], borderColor: '#00E5FF', backgroundColor: 'rgba(0,229,255,0.08)', tension: 0.4, borderWidth: 2.5, pointRadius: 4, fill: true }
        ]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { labels: { color: '#8890A0', font: { family: cfg.font, size: 11 } } } },
        scales: {
          x: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { color: cfg.grid } },
          y: { min: 86, max: 94, ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 }, callback: v => v + '%' }, grid: { color: cfg.grid } }
        }
      }
    });
  }

  if (panel === 3) {
    destroy('chartShap');

    charts['chartShap'] = new Chart(document.getElementById('chartShap'), {
      type: 'bar',
      data: {
        labels: ['balance/adv ratio', 'prior repay score', 'days since payroll', 'avg income', 'overdraft freq', 'tx velocity', 'income stability', 'neobank'],
        datasets: [{ data: [0.241, 0.198, 0.167, 0.143, 0.112, 0.089, 0.053, 0.024], backgroundColor: ['#00E5FF', '#00E5FF', '#845EF7', '#845EF7', '#FFB300', '#FFB300', '#5A6070', '#5A6070'], borderRadius: 4, borderSkipped: false }]
      },
      options: {
        indexAxis: 'y', responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { color: cfg.grid } },
          y: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { display: false } }
        }
      }
    });
  }

  if (panel === 4) {
    destroy('chartLatency');

    charts['chartLatency'] = new Chart(document.getElementById('chartLatency'), {
      type: 'bar',
      data: {
        labels: ['p50', 'p75', 'p90', 'p99'],
        datasets: [{ data: [22, 38, 61, 94], backgroundColor: ['#00E676', '#00E5FF', '#FFB300', '#FF4560'], borderRadius: 4, borderSkipped: false }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 } }, grid: { display: false } },
          y: { ticks: { color: cfg.tick, font: { family: cfg.font, size: 10 }, callback: v => v + 'ms' }, grid: { color: cfg.grid } }
        }
      }
    });
  }
}

setTimeout(() => renderCharts(0), 100);
