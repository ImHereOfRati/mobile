import { useTranslation } from "react-i18next";

interface PlaceholderScreenProps {
  titleKey: string;
}

export function PlaceholderScreen({ titleKey }: PlaceholderScreenProps) {
  const { t } = useTranslation();

  return (
    <section className="placeholder-page">
      <span className="placeholder-page__eyebrow">
        {t("common.placeholder.eyebrow")}
      </span>
      <h1>{t(titleKey)}</h1>
      <p>{t("common.placeholder.description")}</p>
    </section>
  );
}
