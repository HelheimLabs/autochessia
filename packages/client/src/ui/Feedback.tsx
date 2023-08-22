import { Tooltip } from "antd";

export default function Feedback() {
  const linkList: Record<
    string,
    {
      link: string;
      icon: string;
    }
  > = {
    // Feedback: "https://autochessia.canny.io/",
    Github: {
      link: "https://github.com/HelheimLabs/autochessia",
      icon: "https://img.icons8.com/?size=80&id=12598&format=png",
    },
    Discord: {
      link: "https://discord.gg/Qget5JQHtr",
      icon: "https://img.icons8.com/?size=80&id=wtEAYiCLYgtq&format=png",
    },
    X: {
      link: "https://twitter.com/auto_chessia",
      icon: "https://img.icons8.com/?size=80&id=phOKFKYpe00C&format=png",
    },
  };

  function handleClick(item: string) {
    window.open(linkList[item]["link"], "_blank");
  }

  return (
    <div className="fixed  bottom-0 p-4 ">
      {Object.keys(linkList).map((link) => (
        <Tooltip key={link} title={link}>
          <button
            onClick={() => handleClick(link)}
            className=" first:-ml-2 ml-2 rounded-lg bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
          >
            <img className="w-[30px] h-[30px] " src={linkList[link]["icon"]} />
          </button>
        </Tooltip>
      ))}
    </div>
  );
}
