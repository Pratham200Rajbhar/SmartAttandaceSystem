import { redirect } from "next/navigation";

export default async function EditDepartmentRedirect({ params }: { params: Promise<{ id: string }> }): Promise<React.ReactElement> {
  const { id } = await params;
  redirect(`/admin/setup/departments/${id}/edit`);
}
