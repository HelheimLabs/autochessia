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
  movePiece: () => void
  src: string
  alt: string
  index: number
  srcObj:srcObjType
}

function Piece(props: PieceProps) {
  const { hero, movePiece, src, alt, index } = props

  const [position, setPosition] = useState({ x: 0, y: 0 });

  const [isHovering, setIsHovering] = useState(false);

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
    onDragEnter: () => setIsHovering(true),
    onDragLeave: () => setIsHovering(false),
  });


  

  return (
    <Tooltip title={`Lv `}>
      <div>
        <DragItem data={{ src, index }} />
      </div>
    </Tooltip>

  );
}

export default Piece;