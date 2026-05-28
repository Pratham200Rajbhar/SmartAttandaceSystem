"use client";

import React, { useEffect, useState, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { Search, UserPlus, CheckCircle2, Circle, X } from "lucide-react";
import toast from "react-hot-toast";
import api, { getApiErrorMessage } from "@/lib/api";
import GlassBreadcrumb from "@/components/ui/GlassBreadcrumb";
import GlassPageHeader from "@/components/ui/GlassPageHeader";
import GlassCard from "@/components/ui/GlassCard";
import GlassButton from "@/components/ui/GlassButton";
import GlassLoader from "@/components/ui/GlassLoader";
import GlassInput from "@/components/ui/GlassInput";
import GlassSelect from "@/components/ui/GlassSelect";
import GlassBadge from "@/components/ui/GlassBadge";
import type { StudentResponse, ClassResponse } from "@/types";

export default function EnrollStudentsPage(): React.ReactElement {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  
  const [cls, setCls] = useState<ClassResponse | null>(null);
  const [students, setStudents] = useState<StudentResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedDepartment, setSelectedDepartment] = useState("");
  const [selectedSemester, setSelectedSemester] = useState("");
  const [selectedBatch, setSelectedBatch] = useState("");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [enrolling, setEnrolling] = useState(false);

  useEffect(() => {
    async function fetchData(): Promise<void> {
      try {
        const [clsRes, studentsRes] = await Promise.all([
          api.get<ClassResponse[]>("/admin/classes"),
          api.get<StudentResponse[]>("/admin/users/students")
        ]);
        setCls(clsRes.data.find(c => c.id === id) || null);
        setStudents(studentsRes.data);
      } catch {
        toast.error("Failed to load data");
      } finally {
        setLoading(false);
      }
    }
    void fetchData();
  }, [id]);

  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      
      if (selectedDepartment && s.department_name !== selectedDepartment) return false;
      
      if (selectedSemester && String(s.semester) !== selectedSemester) return false;
      
      if (selectedBatch && s.batch !== selectedBatch) return false;
      
      if (searchQuery.trim()) {
        const lowerQ = searchQuery.toLowerCase();
        const nameMatch = `${s.first_name || ""} ${s.last_name || ""}`.toLowerCase().includes(lowerQ);
        const emailMatch = s.email.toLowerCase().includes(lowerQ);
        const enrollMatch = (s.enrollment_number || "").toLowerCase().includes(lowerQ);
        const deptMatch = (s.department_name || "").toLowerCase().includes(lowerQ);
        
        if (!nameMatch && !emailMatch && !enrollMatch && !deptMatch) {
          return false;
        }
      }
      return true;
    });
  }, [students, searchQuery, selectedDepartment, selectedSemester, selectedBatch]);

  const nonEnrolledFilteredStudents = useMemo(() => {
    return filteredStudents.filter(
      (s) => !(cls?.enrolled_student_ids?.includes(s.id) ?? false)
    );
  }, [filteredStudents, cls]);

  const allVisibleSelected = nonEnrolledFilteredStudents.length > 0 && 
    nonEnrolledFilteredStudents.every((s) => selectedIds.has(s.id));

  const filterOptions = useMemo(() => {
    const departments = new Set<string>();
    const semesters = new Set<string>();
    const batches = new Set<string>();
    for (const s of students) {
      if (s.department_name) departments.add(s.department_name);
      if (s.semester) semesters.add(String(s.semester));
      if (s.batch) batches.add(s.batch);
    }
    return {
      uniqueDepartments: Array.from(departments).sort(),
      uniqueSemesters: Array.from(semesters).sort(),
      uniqueBatches: Array.from(batches).sort(),
    };
  }, [students]);

  const toggleSelect = (studentId: string) => {
    const isAlreadyEnrolled = cls?.enrolled_student_ids?.includes(studentId) || false;
    if (isAlreadyEnrolled) return;
    
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(studentId)) next.delete(studentId);
      else next.add(studentId);
      return next;
    });
  };

  const toggleSelectAll = () => {
    if (allVisibleSelected) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        nonEnrolledFilteredStudents.forEach((s) => next.delete(s.id));
        return next;
      });
    } else {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        nonEnrolledFilteredStudents.forEach((s) => next.add(s.id));
        return next;
      });
    }
  };

  async function handleEnroll(): Promise<void> {
    if (selectedIds.size === 0) {
      toast.error("Please select at least one student");
      return;
    }
    setEnrolling(true);
    try {
      const { data } = await api.post<{ enrolled_count: number }>(`/admin/classes/${id}/enroll`, { 
        student_ids: Array.from(selectedIds) 
      });
      toast.success(`${data.enrolled_count} students enrolled successfully`);
      router.push(`/admin/classes/${id}`);
    } catch (err: unknown) {
      toast.error(getApiErrorMessage(err, "Enrollment failed"));
    } finally { 
      setEnrolling(false); 
    }
  }

  if (loading) return <GlassLoader text="Loading students directory..." />;
  if (!cls) return <div className="text-center py-20 text-slate-500">Class not found</div>;

  return (
    <div className="animate-fade-in-up space-y-6">
      <GlassBreadcrumb items={[
        { label: "Admin", href: "/admin/dashboard" }, 
        { label: "Classes", href: "/admin/classes" }, 
        { label: cls.name, href: `/admin/classes/${id}` }, 
        { label: "Enroll Students" }
      ]} />
      
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <GlassPageHeader 
          title="Enroll Students" 
          description={`Select students to enroll in ${cls.name} (${cls.subject_code})`} 
        />
        <div className="flex items-center gap-3 bg-slate-900/50 p-3 rounded-2xl border border-white/5">
          <div className="text-right">
            <p className="text-xs text-slate-400 font-medium uppercase tracking-wider">Selected</p>
            <p className="text-xl font-bold text-white leading-none">{selectedIds.size}</p>
          </div>
          <div className="h-8 w-px bg-white/10 mx-2"></div>
          <GlassButton 
            variant="primary" 
            icon={<UserPlus size={16} />} 
            onClick={handleEnroll}
            loading={enrolling}
            disabled={selectedIds.size === 0}
          >
            Enroll Selected
          </GlassButton>
        </div>
      </div>

      <GlassCard className="!p-0 overflow-hidden relative">
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-white/10 to-transparent"></div>
        
        {}
        <div className="p-4 border-b border-white/5 bg-white/[0.01] flex flex-col gap-4">
          <div className="flex flex-col sm:flex-row gap-4 items-center justify-between">
            <div className="w-full sm:w-96 relative">
              <GlassInput
                label=""
                placeholder="Search by name, email, or enrollment no..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              <Search size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" />
            </div>
            
            <div className="flex items-center gap-3 w-full sm:w-auto ml-auto">
              <GlassButton 
                variant="secondary" 
                onClick={toggleSelectAll}
                className="w-full sm:w-auto"
                disabled={nonEnrolledFilteredStudents.length === 0}
              >
                {allVisibleSelected ? "Deselect All Visible" : "Select All Visible"}
              </GlassButton>
              {selectedIds.size > 0 && (
                <button 
                  onClick={() => setSelectedIds(new Set())}
                  className="p-2.5 text-slate-400 hover:text-slate-300 hover:bg-white/5 rounded-xl transition-colors"
                  title="Clear Selection"
                >
                  <X size={20} />
                </button>
              )}
            </div>
          </div>
          
          {}
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="w-full sm:w-1/3">
              <GlassSelect
                label=""
                options={[
                  { value: "", label: "All Departments" },
                  ...filterOptions.uniqueDepartments.map((d) => ({ value: d, label: d }))
                ]}
                value={selectedDepartment}
                onChange={setSelectedDepartment}
              />
            </div>
            <div className="w-full sm:w-1/3">
              <GlassSelect
                label=""
                options={[
                  { value: "", label: "All Semesters" },
                  ...filterOptions.uniqueSemesters.map((s) => ({ value: s, label: `Semester ${s}` }))
                ]}
                value={selectedSemester}
                onChange={setSelectedSemester}
              />
            </div>
            <div className="w-full sm:w-1/3">
              <GlassSelect
                label=""
                options={[
                  { value: "", label: "All Batches" },
                  ...filterOptions.uniqueBatches.map((b) => ({ value: b, label: `Batch ${b}` }))
                ]}
                value={selectedBatch}
                onChange={setSelectedBatch}
              />
            </div>
          </div>
        </div>

        {}
        <div className="max-h-[600px] overflow-y-auto p-4 space-y-2 custom-scrollbar">
          {filteredStudents.length === 0 ? (
            <div className="text-center py-12 text-slate-500">
              No students found matching your search.
            </div>
          ) : (
            filteredStudents.map((student) => {
              const isSelected = selectedIds.has(student.id);
              const isAlreadyEnrolled = cls?.enrolled_student_ids?.includes(student.id) || false;
              const fullName = student.first_name || student.last_name ? `${student.first_name || ""} ${student.last_name || ""}`.trim() : "Unknown Name";
              
              return (
                <div 
                  key={student.id}
                  onClick={() => toggleSelect(student.id)}
                  className={`group flex items-center gap-4 p-4 rounded-xl border transition-all duration-200 ${
                    isAlreadyEnrolled
                      ? "bg-slate-900/10 border-transparent opacity-40 cursor-not-allowed"
                      : isSelected 
                      ? "bg-white/5 border-white/10 cursor-pointer" 
                      : "bg-slate-800/30 border-transparent hover:border-white/10 hover:bg-white/[0.02] cursor-pointer"
                  }`}
                >
                  <div className={`flex-shrink-0 transition-colors ${
                    isAlreadyEnrolled
                      ? "text-emerald-500"
                      : isSelected 
                      ? "text-slate-300" 
                      : "text-slate-600 group-hover:text-slate-400"
                  }`}>
                    {isAlreadyEnrolled ? <CheckCircle2 size={24} /> : isSelected ? <CheckCircle2 size={24} /> : <Circle size={24} />}
                  </div>
                  
                  <div className="flex-1 grid grid-cols-1 sm:grid-cols-12 gap-4 items-center">
                    <div className="sm:col-span-4">
                      <p className={`font-semibold ${isSelected ? "text-blue-100" : "text-slate-200"}`}>
                        {fullName}
                      </p>
                      <p className="text-xs text-slate-500">{student.email}</p>
                    </div>
                    
                    <div className="sm:col-span-3">
                      <p className="text-sm text-slate-300 font-mono">
                        {student.enrollment_number || "No ID"}
                      </p>
                      <p className="text-xs text-slate-500">Enrollment No.</p>
                    </div>
                    
                    <div className="sm:col-span-3 flex items-center gap-2">
                      {student.department_name ? (
                        <GlassBadge variant="neutral" className="text-xs">{student.department_name}</GlassBadge>
                      ) : (
                        <span className="text-xs text-slate-500">—</span>
                      )}
                      {isAlreadyEnrolled && (
                        <GlassBadge variant="success" className="text-[10px] uppercase font-bold tracking-wider">Enrolled</GlassBadge>
                      )}
                    </div>
                    
                    <div className="sm:col-span-2 text-right hidden sm:block">
                      <span className="text-xs text-slate-600 font-mono" title={student.id}>
                        {student.id.substring(0, 8)}...
                      </span>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </GlassCard>
    </div>
  );
}
