"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useParams } from "next/navigation";
import dynamic from "next/dynamic";
import { useMapEvents, useMap } from "react-leaflet";
import toast from "react-hot-toast";
import { Save, Download, Navigation } from "lucide-react";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassInput from "@/components/ui/GlassInput";
import GlassSlider from "@/components/ui/GlassSlider";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import type { AcademicClassWithGeofence, AttendanceExportRow } from "@/types";

const MapContainer = dynamic(() => import("react-leaflet").then((m) => m.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then((m) => m.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then((m) => m.Marker), { ssr: false });
const Circle = dynamic(() => import("react-leaflet").then((m) => m.Circle), { ssr: false });

function MapClickHandler({ onLocationSelect }: { onLocationSelect: (lat: number, lng: number) => void }): null {
  useMapEvents({ click: (e: { latlng: { lat: number; lng: number } }) => onLocationSelect(e.latlng.lat, e.latlng.lng) });
  return null;
}

function MapUpdater({ lat, lng }: { lat: number; lng: number }): null {
  const map = useMap();
  useEffect(() => {
    map.flyTo([lat, lng], map.getZoom());
  }, [lat, lng, map]);
  return null;
}

async function downloadCsv(rows: AttendanceExportRow[], fileName: string): Promise<void> {
  
  const Papa = (await import("papaparse")).default;
  const csv = Papa.unparse(rows);
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = fileName;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  URL.revokeObjectURL(url);
}

export default function ClassDetailPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const [cls, setCls] = useState<AcademicClassWithGeofence | null>(null);
  const [lat, setLat] = useState(28.6139);
  const [lng, setLng] = useState(77.209);
  const [radius, setRadius] = useState(100);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [mapReady, setMapReady] = useState(false);

  const [exporting, setExporting] = useState(false);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");

  useEffect(() => {
    async function fetchClass(): Promise<void> {
      try {
        const { data } = await api.get<AcademicClassWithGeofence[]>("/teacher/my-classes");
        const found = data.find((c) => c.id === id);
        if (found) {
          setCls(found);
          if (found.geofence) {
            setLat(found.geofence.latitude);
            setLng(found.geofence.longitude);
            setRadius(found.geofence.radiusMeters);
          }
        }
      } catch (err: unknown) {
        toast.error(getApiErrorMessage(err, "Failed to load class details"));
      } finally {
        setLoading(false);
      }
    }
    void fetchClass();

    import("leaflet/dist/leaflet.css");
    import("leaflet").then((L) => {
      
      interface DefaultIconPrototype {
        _getIconUrl?: unknown;
      }
      delete (L.Icon.Default.prototype as DefaultIconPrototype)._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
        iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
        shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
      });
      setMapReady(true);
    });
  }, [id]);

  const handleLocationSelect = useCallback((newLat: number, newLng: number) => {
    setLat(newLat);
    setLng(newLng);
  }, []);

  const handleGetCurrentLocation = useCallback(() => {
    if (!navigator.geolocation) {
      toast.error("Geolocation is not supported by your browser");
      return;
    }
    toast.loading("Fetching location...", { id: "geo" });
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(pos.coords.latitude);
        setLng(pos.coords.longitude);
        toast.success("Location updated", { id: "geo" });
      },
      (err) => {
        toast.error(`Failed to get location: ${err.message}`, { id: "geo" });
      },
      { enableHighAccuracy: true }
    );
  }, []);

  async function handleSave(): Promise<void> {
    setSaving(true);
    try {
      await api.post(`/teacher/classes/${id}/geofence`, {
        latitude: lat,
        longitude: lng,
        radius_meters: radius,
      });
      toast.success("Geofence saved successfully");
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Failed to save geofence"));
    } finally {
      setSaving(false);
    }
  }

  async function handleExportCsv(): Promise<void> {
    setExporting(true);
    try {
      const params = new URLSearchParams();
      if (fromDate) params.set("from_date", new Date(fromDate).toISOString());
      if (toDate) params.set("to_date", new Date(toDate).toISOString());
      const query = params.toString() ? `?${params.toString()}` : "";

      const { data } = await api.get<AttendanceExportRow[]>(
        `/teacher/classes/${id}/export-attendance${query}`
      );

      if (data.length === 0) {
        toast("No attendance records found for the selected range.", { icon: "ℹ️" });
        return;
      }

      const today = new Date().toISOString().slice(0, 10);
      const className = cls?.name?.replace(/\s+/g, "_") ?? "class";
      await downloadCsv(data, `attendance_${className}_${today}.csv`);
      toast.success(`Downloaded ${data.length} record(s)`);
    } catch {
      toast.error("Export failed");
    } finally {
      setExporting(false);
    }
  }

  if (loading) return <GlassLoader text="Loading class..." />;
  if (!cls) return <div className="text-center py-20 text-slate-500">Class not found</div>;

  return (
    <div className="animate-fade-in-up">
      <GlassBreadcrumb
        items={[{ label: "My Classes", href: "/teacher/classes" }, { label: cls.name }]}
      />
      {}
      <GlassPageHeader
        title={cls.name}
        description={`${cls.subject} — Configure geofence and export attendance`}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {}
        <div className="lg:col-span-2">
          <GlassCard padding="sm" className="overflow-hidden">
            <div className="relative" style={{ height: 450, borderRadius: 12, overflow: "hidden" }}>
              {mapReady ? (
                <>
                  <MapContainer
                    center={[lat, lng]}
                    zoom={16}
                    style={{ height: "100%", width: "100%" }}
                    scrollWheelZoom
                  >
                    <TileLayer
                      attribution='&copy; <a href="https://carto.com">CARTO</a>'
                      url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                    />
                    <MapClickHandler onLocationSelect={handleLocationSelect} />
                    <MapUpdater lat={lat} lng={lng} />
                    <Marker position={[lat, lng]} />
                    <Circle
                      center={[lat, lng]}
                      radius={radius}
                      pathOptions={{
                        color: "#3b82f6",
                        fillColor: "#3b82f6",
                        fillOpacity: 0.15,
                        weight: 2,
                      }}
                    />
                  </MapContainer>
                  <div className="absolute top-4 right-4 z-[400]">
                    <GlassButton
                      variant="primary"
                      size="sm"
                      icon={<Navigation size={16} />}
                      onClick={handleGetCurrentLocation}
                    >
                      Current Location
                    </GlassButton>
                  </div>
                </>
              ) : (
                <div className="flex items-center justify-center h-full text-slate-500">
                  Loading map...
                </div>
              )}
            </div>
          </GlassCard>
        </div>

        {}
        <div className="space-y-6">
          {}
          <GlassCard>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">
              Geofence Settings
            </h3>
            <div className="space-y-4">
              <div>
                <p className="text-xs text-slate-500 mb-1">Latitude</p>
                <p className="text-sm font-mono text-slate-200">{lat.toFixed(6)}</p>
              </div>
              <div>
                <p className="text-xs text-slate-500 mb-1">Longitude</p>
                <p className="text-sm font-mono text-slate-200">{lng.toFixed(6)}</p>
              </div>
              <GlassSlider
                label="Radius"
                min={10}
                max={500}
                step={5}
                value={radius}
                onChange={setRadius}
                unit="m"
              />
            </div>
          </GlassCard>

          <GlassButton
            variant="primary"
            size="lg"
            className="w-full animate-pulse-glow"
            onClick={() => void handleSave()}
            loading={saving}
            icon={<Save size={18} />}
          >
            Save Geofence
          </GlassButton>

          <GlassCard padding="sm">
            <p className="text-xs text-slate-500 text-center">
              Click on the map to set the geofence center point
            </p>
          </GlassCard>

          {}
          <GlassCard>
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">
              Export Attendance
            </h3>
            <div className="space-y-3">
              <GlassInput
                label="From Date (optional)"
                type="date"
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
              />
              <GlassInput
                label="To Date (optional)"
                type="date"
                value={toDate}
                onChange={(e) => setToDate(e.target.value)}
              />
              <GlassButton
                variant="ghost"
                size="md"
                className="w-full"
                icon={<Download size={16} />}
                loading={exporting}
                onClick={() => void handleExportCsv()}
              >
                Export CSV
              </GlassButton>
            </div>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
