import React, { useState, useRef } from "react";
import { useDrop, useDrag } from "ahooks";
import { srcObjType } from "@/hooks/useChessboard";

import { Tooltip } from "antd";

const empty =
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAACCklEQVR4nO3BMQEAAADCoPVPbQ0PoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA3vOtDwABvgfsPAABJEFAQAYEBAVgQEAGBARkYEBABgYEZGBAQAYEAjIgICAD/gCED1OUj/kPuwAAAABJRU5ErkJggg==";

interface IDrap {
  data: {
    src: string;
    index: number;
  };
}

const DragItem = ({ data }: IDrap) => {
  const { src } = data;
  const dragRef = useRef(null);

  useDrag(data, dragRef, {
    onDragStart: (e) => {
      console.log(e);
    },
    onDragEnd: (e) => {
      console.log(e);
    },
  });

  const srcImg = src || empty;

  return (
    <div ref={dragRef}>
      <img
        style={{
          height: "100%",
          width: 60,
        }}
        src={srcImg}
        alt={srcImg}
      />
    </div>
  );
};

interface PieceProps {
  hero: any;
  src: string;
  alt: string;
  index: number;
  srcObj: srcObjType;
  sellHero: (arg0: number) => void;
  placeBackInventory: (arg0: number, arg1: number) => void;
}

function Piece(props: PieceProps) {
  const { hero, src, index, sellHero, placeBackInventory } = props;

  const dropRef = useRef(null);

  const [dragIng, setDragIng] = useState(false);

  useDrop(dropRef, {
    // onText: (text, e) => {
    //   console.log(e);
    //   alert(`'text: ${text}' dropped`);
    // },
    // onFiles: (files, e) => {
    //   console.log(e, files);
    //   alert(`${files.length} file dropped`);
    // },
    // onUri: (uri, e) => {
    //   console.log(e);
    //   alert(`uri: ${uri} dropped`);
    // },
    // onDom: (content: string, e) => {
    //   alert(`custom: ${content} dropped`);
    // },

    onDom: (content: any) => {
      // console.log(content, "content", dropRef?.current?.dataset?.index);
      // const moveIndex = PiecesList!.findIndex(item => item.creatureId == content.creatureId)
      placeBackInventory(content._index, dropRef?.current?.dataset?.index);
    },
    onDragEnter: (e) => {
      if (!dragIng) {
        setDragIng(true);
      }
    },
    onDrop: (e) => {
      setDragIng(false);
    },
  });

  const Wrap = hero.creature > 0 ? Tooltip : "div";

  return (
    <Wrap
      // title={hero.creature > 0 ? `Lv ${hero.lv}  Cost ${hero.cost}` : ""}
      ref={dropRef}
      data-index={index}
    >
      <div className={`relative group  inventory-hero`}>
        {hero.creature > 0 && (
          <>
            <button
              onClick={() => sellHero(index)}
              className="bg-red-500 hover:bg-red-600 text-white   w-4 h-4  text-xs absolute  -right-2 -top-2 group-hover:block  hidden  rounded"
            >
              x
            </button>
            <div className="text-yellow-400  text-sm absolute bottom-0 -left-0">
              {Array(hero["lv"])
                .fill(null)
                ?.map((item, index) => (
                  <span className="" key={index}>
                    &#9733;
                  </span>
                ))}
            </div>
          </>
        )}
        <DragItem
          data={{
            src,
            index,
          }}
        />
      </div>
    </Wrap>
  );
}

export default Piece;
