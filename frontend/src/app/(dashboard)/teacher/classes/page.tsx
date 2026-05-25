"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { MapPin, BookOpen, ArrowRight } from "lucide-react";
import api from "@/lib/api";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassBadge from "@/components/ui/GlassBadge";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassEmptyState from "@/components/ui/GlassEmptyState";
import type { AcademicClassWithGeofence } from "@/types";

export default function TeacherClassesPage(): React.ReactElement {
  const router = useRouter();
  const [classes, setClasses] = useState<AcademicClassWithGeofence[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetch(): Promise<void> {
      try { 
        const { data } = await api.get<AcademicClassWithGeofence[]>("/teacher/my-classes"); 
        setClasses(data); 
      }
      catch { 
        setClasses([]); 
      }
      finally { 
        setLoading(false); 
      }
    }
    fetch();
  }, []);

  if (loading) return <GlassLoader text="Loading your classes..." />;

  return (
    <div className="animate-fade-in-up space-y-8">
      <GlassPageHeader title="My Classes" description="Manage class parameters and configure geofence details" />

      {classes.length === 0 ? (
        <GlassEmptyState title="No Classes Assigned" message="Contact your administrator to get assigned to classes." />
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {classes.map((cls) => (
            <GlassCard 
              key={cls.id} 
              hoverable 
              padding="lg" 
              onClick={() => router.push(`/teacher/classes/${cls.id}`)}
              className="group cursor-pointer hover:border-white/10 transition-all duration-300 relative overflow-hidden"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="p-2.5 rounded-xl bg-white/5 text-slate-300 group-hover:bg-white/5 group-hover:text-slate-300 transition-all">
                  <BookOpen size={20} />
                </div>
                {cls.geofence ? (
                  <GlassBadge variant="success" className="font-semibold"><MapPin size={10} className="mr-1" /> Configured</GlassBadge>
                ) : (
                  <GlassBadge variant="neutral" className="font-semibold">No Geofence</GlassBadge>
                )}
              </div>
              
              <h3 className="text-lg font-bold text-slate-100 mb-1 group-hover:text-indigo-300 transition-colors font-[Outfit] tracking-wide">{cls.name}</h3>
              <p className="text-sm font-semibold text-slate-400">{cls.subject}</p>
              
              <div className="border-t border-white/5 mt-4 pt-4 flex items-center justify-between">
                <div>
                  {cls.geofence ? (
                    <span className="text-xs font-semibold text-slate-500">
                      Radius: <strong className="text-slate-300">{cls.geofence.radiusMeters}m</strong>
                    </span>
                  ) : (
                    <span className="text-xs font-medium text-slate-600">Pending Setup</span>
                  )}
                </div>
                <div className="flex items-center gap-1 text-xs font-bold text-slate-300 opacity-0 group-hover:opacity-100 transition-all transform translate-x-2 group-hover:translate-x-0">
                  <span>Configure</span>
                  <ArrowRight size={12} />
                </div>
              </div>
            </GlassCard>
          ))}
        </div>
      )}
    </div>
  );
}
