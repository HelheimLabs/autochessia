import React, { useState, useRef } from 'react';
import { useDrop, useDrag } from 'ahooks';


const DragItem = ({ data }) => {
  const dragRef = useRef(null);

  const [dragging, setDragging] = useState(false);



  useDrag(data, dragRef, {
    onDragStart: () => {
      setDragging(true);
    },
    onDragEnd: () => {
      setDragging(false);
    },
  });

  return (
    <div
      ref={dragRef}
    // style={{
    //   border: '1px solid #e8e8e8',
    //   padding: 16,
    //   width: 80,
    //   textAlign: 'center',
    //   marginRight: 16,
    // }}
    >
      {/* {dragging ? 'dragging' : `box-${data}`} */}

      <img
        // draggable
        style={{
          // position: 'absolute',
          //   left: position.x * 50 + 'px',
          //   top: position.y * 50 + 'px',
          height: 50
        }}
        // onDrag={handleDrag}
        // onDragEnd={handleDragEnd}

        // {...props}
        src={data.src}
        alt={data.src}
      />
    </div>
  );
};

function Piece(props) {
  const { hero, movePiece, src, alt,index } = props

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

  function convertToIndex(x: number, y: number): number {
    if (x < 0 || x > 7 || y < 0 || y > 7) {
      throw new Error('Out of range');
    }
    return y * 8 + x;
  }


  function handleDragEnd(e) {
    const mousePosition = {
      x: e.clientX,
      y: e.clientY
    };
    const boundingRect = e.currentTarget.getBoundingClientRect();

    // 考虑元素边框的偏差
    const mouseX = e.clientX - boundingRect.left - (boundingRect.width / 50) / 2;
    const mouseY = e.clientY - boundingRect.top - (boundingRect.height / 50) / 2;

    // const gridX = Math.floor(mouseX / 50);
    // const gridY = Math.floor(mouseY / 50)-1;


    const gridX = Math.floor(e.clientX / 50);
    const gridY = Math.floor((e.clientY / 50) - 1);
    console.log(gridX, gridY, convertToIndex(gridX, gridY));
    movePiece({
      site: convertToIndex(gridX, gridY),
      hero
    })
  }



  function handleDrag(e) {
    // 计算当前鼠标位置对应的格子
    const mousePosition = {
      x: e.clientX,
      y: e.clientY
    };
    // const boundingRect = e.currentTarget.getBoundingClientRect();

    //   // 考虑元素边框的偏差
    //   const mouseX = e.clientX - boundingRect.left - (boundingRect.width / 50) / 2; 
    //   const mouseY = e.clientY - boundingRect.top - (boundingRect.height / 50) / 2;  

    //   const gridX = Math.floor(mouseX / 50);
    //   const gridY = Math.floor(mouseY / 50)-1;

    const gridX = Math.floor(e.clientX / 50);
    const gridY = Math.floor((e.clientY / 50) - 1);

    console.log(gridX, gridY)
    // 设置新的坐标
    setPosition({ x: gridX, y: gridY });
    // hero


  }

  return (
    <DragItem data={{src,index}} />
  );
}

export default Piece;