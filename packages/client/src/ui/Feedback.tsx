export default function Feedback() {
  function handleClick() {
    window.open("https://autochessia.canny.io/", "_blank");
  }

  function openGit() {
    window.open("https://github.com/HelheimLabs/autochessia", "_blank");
  }

  function openDiscord() {
    window.open("https://discord.gg/Qget5JQHtr", "_blank");
  }

  function openTwitter() {
    window.open("https://twitter.com/auto_chessia", "_blank");
  }

  return (
    <div className="fixed  bottom-0 p-4 ">
      <button
        onClick={handleClick}
        className="rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
      >
        Feedback
      </button>

      <button
        onClick={openGit}
        className="ml-2 rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
      >
        Github
      </button>

      <button
        onClick={openDiscord}
        className="ml-2 rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
      >
        Discord
      </button>

      <button
        onClick={openTwitter}
        className="ml-2 rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
      >
        X
      </button>
    </div>
  );
}
