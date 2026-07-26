import { useTranslation } from "react-i18next";
import { isRouteErrorResponse, useRouteError } from "react-router-dom";

export function RouteErrorFallback() {
  const { t } = useTranslation();
  const error = useRouteError();
  const isNotFound = isRouteErrorResponse(error) && error.status === 404;

  return (
    <main className="fallback-page" role="alert">
      <h1>
        {t(
          isNotFound
            ? "common.notFound.title"
            : "common.errors.unexpectedTitle",
        )}
      </h1>
      <p>
        {t(
          isNotFound
            ? "common.notFound.description"
            : "common.errors.unexpectedDescription",
        )}
      </p>
    </main>
  );
}
