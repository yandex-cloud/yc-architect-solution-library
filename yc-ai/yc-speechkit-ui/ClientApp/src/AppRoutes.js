import { Counter } from "./components/Counter";
import { FetchData } from "./components/FetchData";
import { SpeechKitSR } from "./components/SpeechKitSR"
import { Home } from "./components/Home";

const AppRoutes = [
  {
    index: true,
    element: <Home />
    },
    {
        path: '/speech-kit-asr',
        element: <SpeechKitSR />
    },
  {
    path: '/counter',
    element: <Counter />
  },
  {
    path: '/fetch-data',
    element: <FetchData />
  }
];

export default AppRoutes;
