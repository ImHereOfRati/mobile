import { Component, type ErrorInfo, type ReactNode } from "react";
import { withTranslation, type WithTranslation } from "react-i18next";

interface AppErrorBoundaryProps extends WithTranslation {
  children: ReactNode;
}

interface AppErrorBoundaryState {
  hasError: boolean;
}

class AppErrorBoundaryComponent extends Component<
  AppErrorBoundaryProps,
  AppErrorBoundaryState
> {
  state: AppErrorBoundaryState = {
    hasError: false,
  };

  static getDerivedStateFromError(): AppErrorBoundaryState {
    return {
      hasError: true,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Unhandled React render error", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <main className="fallback-page" role="alert">
          <h1>{this.props.t("common.errors.unexpectedTitle")}</h1>
          <p>{this.props.t("common.errors.unexpectedDescription")}</p>
        </main>
      );
    }

    return this.props.children;
  }
}

export const AppErrorBoundary = withTranslation()(AppErrorBoundaryComponent);
