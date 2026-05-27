import { redirect } from "next/navigation";

export default function DepartmentsRedirect(): React.ReactElement {
  redirect("/admin/setup/departments");
}
