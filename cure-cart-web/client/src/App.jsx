import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Prescriptions from "./pages/Prescriptions"; // ✅ new page
// import Home from "./pages/Home"; // add when you have a homepage

export default function App() {
  return (
    <div className="text-slate-800">
      <Router>
        <Routes>
          {/* Example home route */}
          {/* <Route path="/" element={<Home />} /> */}

          {/* Prescriptions route */}
          <Route path="/prescriptions" element={<Prescriptions />} />
        </Routes>
      </Router>
    </div>
  );
}
