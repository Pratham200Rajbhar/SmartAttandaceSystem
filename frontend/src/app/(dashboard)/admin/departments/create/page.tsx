import { redirect } from "next/navigation";

export default function DepartmentsCreateRedirect(): React.ReactElement {
  redirect("/admin/setup/departments/create");
}
