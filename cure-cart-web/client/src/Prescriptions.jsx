import { useEffect, useState } from "react";
import { io } from 'socket.io-client';

export default function Prescriptions() {
  const [prescriptions, setPrescriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [previewUrl, setPreviewUrl] = useState(null);

  useEffect(() => {
    const fetchPrescriptions = async () => {
      try {
        const response = await fetch("http://localhost:4000/api/prescriptions");
        const data = await response.json();
        setPrescriptions(data);
      } catch (err) {
        console.error("❌ Error fetching prescriptions:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchPrescriptions();
  }, []);

  useEffect(() => {
    const socket = io('http://localhost:4000', { path: '/socket.io', transports: ['websocket'] });
    const onNew = (p) => setPrescriptions((prev) => [p, ...prev]);
    const onUpdated = (p) => setPrescriptions((prev) => prev.map(x => x._id === p._id ? p : x));
    socket.on('prescription:new', onNew);
    socket.on('prescription:updated', onUpdated);
    return () => {
      socket.off('prescription:new', onNew);
      socket.off('prescription:updated', onUpdated);
      socket.close();
    };
  }, []);

  if (loading) {
    return <p className="text-center text-gray-500">Loading prescriptions...</p>;
  }

  return (
    <div className="p-6">
      <h1 className="text-xl font-bold mb-4">Uploaded Prescriptions</h1>

      {prescriptions.length === 0 ? (
        <p className="text-gray-500">No prescriptions found.</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {prescriptions.map((p) => (
            <div
              key={p._id}
              className="bg-white shadow-md rounded-lg p-4 border border-gray-200"
            >
              <img
                src={p.imageUrl}
                alt="Prescription"
                className="w-full h-48 object-cover rounded-md cursor-zoom-in"
                onClick={() => setPreviewUrl(p.imageUrl)}
              />
              <h2 className="mt-3 font-semibold">
                {p.patientName || "Unknown Patient"}
              </h2>
              <p className="text-sm text-gray-500">
                Status: <span className="font-medium">{p.status}</span>
              </p>
              <p className="text-sm text-gray-500">
                Address: <span className="font-medium">{p.customerAddress || '-'}</span>
              </p>
              {p.notes && (
                <p className="text-sm text-gray-600 mt-2">{p.notes}</p>
              )}
              <p className="text-xs text-gray-400 mt-2">
                Uploaded: {new Date(p.createdAt).toLocaleString()}
              </p>
            </div>
          ))}
        </div>
      )}
      {previewUrl && (
        <div
          className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4"
          onClick={() => setPreviewUrl(null)}
        >
          <div className="relative max-w-5xl w-full" onClick={(e) => e.stopPropagation()}>
            <button
              className="absolute -top-2 -right-2 bg-white text-slate-700 rounded-full w-8 h-8 shadow hover:bg-slate-100"
              onClick={() => setPreviewUrl(null)}
              aria-label="Close"
            >
              ✕
            </button>
            <img src={previewUrl} alt="Prescription" className="w-full max-h-[80vh] object-contain rounded" />
          </div>
        </div>
      )}
    </div>
  );
}
