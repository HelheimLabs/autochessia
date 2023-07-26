
export default function Feedback() {

  function handleClick() {
    window.open('https://autochessia.canny.io/', '_blank');
  }

  return (
    <div className="fixed inset-x-0 bottom-0 flex justify-center p-4">

      <div className="flex items-center rounded-lg bg-gradient-to-r from-indigo-500 to-purple-500 p-4">

        <svg className="h-5 w-5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
        </svg>

        <div className="text-sm text-white ml-3">
          Love our Game?
        </div>

        <button
          onClick={handleClick}
          className="rounded-full bg-indigo-400 hover:bg-indigo-300 text-white text-xs font-semibold px-2 py-1 transition duration-150 ease-in-out ml-4"
        >
          Give Feedback
        </button>

      </div>

      <div className="absolute inset-0 gradient-border -z-10 animation-spin"></div>

    </div>
  );

}