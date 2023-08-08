export default function Feedback() {
  function handleClick() {
    window.open("https://autochessia.canny.io/", "_blank");
  }

  return (
    <div className="fixed  bottom-0 p-4 mx-4">
      <button
        onClick={handleClick}
        className="rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out "
      >
        Give Feedback
      </button>
    </div>
  );
}
