"use client";

import { useState } from "react";

const CHAT_URL = "https://chatgpt.com/";
const CHART_URL =
  "https://www.tradingview.com/chart/?symbol=OANDA%3AXAUUSD&interval=15";

function ArrowIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24">
      <path d="M8 16 16 8M9 8h7v7" />
    </svg>
  );
}

function ChartPanel() {
  return (
    <section className="panel chart-panel" aria-label="Live XAUUSD chart">
      <div className="panel-head">
        <div>
          <span className="eyebrow">LIVE CHART</span>
          <h2>XAUUSD · 15m</h2>
        </div>
        <span className="live-pill"><i /> Market view</span>
      </div>

      <div className="chart-frame">
        <iframe
          title="TradingView XAUUSD 15 minute chart"
          src="https://s.tradingview.com/widgetembed/?symbol=OANDA%3AXAUUSD&interval=15&theme=dark&style=1&timezone=Etc%2FUTC&withdateranges=1&hide_side_toolbar=0&allow_symbol_change=0&saveimage=0&calendar=0&details=0&hotlist=0"
          loading="eager"
          allowFullScreen
        />
      </div>

      <a className="primary-action" href={CHART_URL} target="_blank" rel="noreferrer">
        Open full TradingView chart <ArrowIcon />
      </a>
      <p className="microcopy">Opens TradingView with XAUUSD selected. Sign in there if asked.</p>
    </section>
  );
}

function ChatPanel() {
  return (
    <section className="panel chat-panel" aria-label="ChatGPT access">
      <div className="panel-head">
        <div>
          <span className="eyebrow">YOUR ASSISTANT</span>
          <h2>Gold chat</h2>
        </div>
        <span className="safe-pill">Manual only</span>
      </div>

      <div className="chat-preview" aria-hidden="true">
        <div className="message user-message">Check XAUUSD and mark the next valid zone.</div>
        <div className="message assistant-message">
          <span className="assistant-mark">G</span>
          <p>I’ll review the live 15-minute chart. No trade will be placed automatically.</p>
        </div>
      </div>

      <a className="primary-action" href={CHAT_URL} target="_blank" rel="noreferrer">
        Open ChatGPT <ArrowIcon />
      </a>
      <div className="privacy-note">
        <span>Shared account notice</span>
        Everyone using the same ChatGPT account may see its chat history.
      </div>
    </section>
  );
}

export default function Home() {
  const [tab, setTab] = useState<"chart" | "chat">("chart");

  return (
    <main>
      <header className="topbar">
        <a className="brand" href="#top" aria-label="GoldDesk home">
          <span className="brand-mark">G</span>
          <span>GoldDesk</span>
        </a>
        <div className="status"><i /> Review mode</div>
      </header>

      <div id="top" className="hero">
        <div>
          <span className="eyebrow">XAUUSD WORKSPACE</span>
          <h1>Your chart and chat,<br /><em>together.</em></h1>
        </div>
        <p>One clean place to review gold on your Mac or iPhone. You stay in control of every entry.</p>
      </div>

      <nav className="mobile-tabs" aria-label="Choose view">
        <button className={tab === "chart" ? "active" : ""} onClick={() => setTab("chart")}>Chart</button>
        <button className={tab === "chat" ? "active" : ""} onClick={() => setTab("chat")}>Chat</button>
      </nav>

      <div className={`workspace show-${tab}`}>
        <ChartPanel />
        <ChatPanel />
      </div>

      <section className="guardrail" aria-label="Safety information">
        <div className="guardrail-icon">✓</div>
        <div>
          <strong>You make the final decision</strong>
          <p>GoldDesk does not place, close, or modify live or demo trades. Always check the live price before acting.</p>
        </div>
      </section>

      <section className="install-card">
        <span className="step-number">01</span>
        <div>
          <span className="eyebrow">IPHONE SETUP</span>
          <h2>Keep GoldDesk one tap away</h2>
          <ol>
            <li>Open this page in Safari</li>
            <li>Tap the Share button</li>
            <li>Choose “Add to Home Screen”</li>
          </ol>
        </div>
      </section>

      <footer>
        <span>GoldDesk</span>
        <p>Built for focused chart review · Not financial advice</p>
      </footer>
    </main>
  );
}
