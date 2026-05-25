"use client";

import { useParams } from "next/navigation";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function SessionRedirectPage(): null {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();

  useEffect(() => {
    router.replace(`/teacher/sessions/${id}/roster`);
  }, [id, router]);

  return null;
}
