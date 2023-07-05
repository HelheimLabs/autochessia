import React, { useState, useRef } from 'react';
import { useDrop, useDrag } from 'ahooks';
import { srcObjType } from './ChessMain';

import { Tooltip } from 'antd';

const DragItem = ({ data }) => {
  const dragRef = useRef(null);

  const [dragging, setDragging] = useState(false);



  useDrag(data, dragRef, {
    onDragStart: (e) => {
      console.log(e)
    },
    onDragEnd: (e) => {
      console.log(e)
    },
  });

  return (
    <div
      ref={dragRef}
    >
      {/* {dragging ? 'dragging' : `box-${data}`} */}
      <img
        style={{
          height: 50
        }}
        src={data.src}
        alt={data.src}
      />
    </div>
  );
};



interface PieceProps {
  hero: any
  src: string
  alt: string
  index: number
  srcObj: srcObjType
  sellHero: () => void
}

function Piece(props: PieceProps) {
  const { hero, movePiece, src, alt, index,sellHero } = props

  // console.log(hero)



  const dropRef = useRef(null);

  useDrop(dropRef, {
    onText: (text, e) => {
      console.log(e);
      alert(`'text: ${text}' dropped`);
    },
    onFiles: (files, e) => {
      console.log(e, files);
      alert(`${files.length} file dropped`);
    },
    onUri: (uri, e) => {
      console.log(e);
      alert(`uri: ${uri} dropped`);
    },
    onDom: (content: string, e) => {
      alert(`custom: ${content} dropped`);
    },

  });




  return (
    <Tooltip title={`Lv ${hero.lv} Cost ${hero.cost}`}>
      <div className='relative group'>
        <button onClick={()=>sellHero(index)} className="bg-red-500 hover:bg-red-600 text-white   w-4 h-4  text-xs absolute  -right-2 -top-2 group-hover:block  hidden  rounded">
          x
        </button>
        <DragItem data={{ src, index }} />
      </div>
    </Tooltip>

  );
}

export default Piece;