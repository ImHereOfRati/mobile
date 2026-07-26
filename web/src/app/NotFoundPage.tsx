import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";

export function NotFoundPage() {
  const { t } = useTranslation();

  return (
    <main className="fallback-page">
      <h1>{t("common.notFound.title")}</h1>
      <p>{t("common.notFound.description")}</p>
      <Link to="/auth">{t("common.notFound.action")}</Link>
    </main>
  );
}
