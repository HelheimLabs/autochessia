import React, { useState } from 'react';

const CardDraw = () => {
  const [cards, setCards] = useState([
    { name: 'hero1', cost: 1, src: 'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/48b4-imztzhn1606827.jpg' },
    { name: 'hero2', cost: 2, src: 'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/86ed-imztzhn1610595.jpg' },
    { name: 'hero3', cost: 1, src: "https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/99ee-imztzhn1610686.jpg" },
    { name: 'hero4', cost: 2, src: "https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/99ee-imztzhn1610686.jpg" },
    { name: 'hero5', cost: 1, src: "https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/99ee-imztzhn1610686.jpg" }
  ]);
  const [drawnCards, setDrawnCards] = useState<{ name: string; image: string; }[]>([]);

  const drawCard = () => {
    if (cards.length > 0) {
      const randomIndex = Math.floor(Math.random() * cards.length);
      const drawnCard = cards[randomIndex];
      setDrawnCards([...drawnCards, drawnCard]);
      setCards(cards.filter(c => c !== drawnCard));
    }
  }

  const renderDrawnCards = () => {
    return drawnCards.map(c => {
      return (
        <img src={c.image} alt={c.name} />
      )
    })
  }

  return (
    <div>
      <div className="draw-pile">{cards.length} remaining</div>
      <button onClick={drawCard}>Draw Card</button>
      <div className="drawn-cards">
        {renderDrawnCards()}
      </div>
    </div>
  );
}

export default CardDraw;