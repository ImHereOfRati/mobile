import {
  type ButtonHTMLAttributes,
  type ElementType,
  type InputHTMLAttributes,
  type PropsWithChildren,
  type ReactNode,
  useEffect,
  useId,
  useRef,
} from "react";

type ButtonVariant = "primary" | "secondary" | "ghost" | "text" | "danger";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  loading?: boolean;
  variant?: ButtonVariant;
}

export function Button({
  children,
  className = "",
  disabled,
  loading = false,
  type = "button",
  variant = "primary",
  ...props
}: ButtonProps) {
  return (
    <button
      className={`ds-button ds-button--${variant} ${className}`.trim()}
      disabled={disabled || loading}
      type={type}
      aria-busy={loading}
      {...props}
    >
      {loading ? (
        <>
          <span className="ds-spinner" aria-hidden="true" />
          <span>처리 중</span>
        </>
      ) : (
        children
      )}
    </button>
  );
}

interface TextFieldProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: string;
  helperText?: string;
  label: string;
}

export function TextField({
  className = "",
  error,
  helperText,
  id,
  label,
  ...props
}: TextFieldProps) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const descriptionId =
    error === undefined && helperText === undefined
      ? undefined
      : `${inputId}-description`;

  return (
    <label className={`ds-field ${className}`.trim()} htmlFor={inputId}>
      <span className="ds-field__label">{label}</span>
      <input
        className="ds-field__input"
        id={inputId}
        aria-describedby={descriptionId}
        aria-invalid={error === undefined ? undefined : true}
        {...props}
      />
      {error !== undefined ? (
        <span className="ds-field__error" id={descriptionId} role="alert">
          {error}
        </span>
      ) : helperText !== undefined ? (
        <span className="ds-field__helper" id={descriptionId}>
          {helperText}
        </span>
      ) : null}
    </label>
  );
}

interface CardProps extends PropsWithChildren {
  className?: string;
  description?: string;
  title?: string;
}

export function Card({
  children,
  className = "",
  description,
  title,
}: CardProps) {
  return (
    <article className={`ds-card ${className}`.trim()}>
      {title === undefined ? null : (
        <header className="ds-card__header">
          <h3 className="type-headline-small">{title}</h3>
          {description === undefined ? null : (
            <p className="type-body-medium">{description}</p>
          )}
        </header>
      )}
      {children}
    </article>
  );
}

interface BottomSheetProps extends PropsWithChildren {
  closeLabel?: string;
  onClose: () => void;
  open: boolean;
  title: string;
}

export function BottomSheet({
  children,
  closeLabel = "바텀시트 닫기",
  onClose,
  open,
  title,
}: BottomSheetProps) {
  const titleId = useId();
  const sheetRef = useRef<HTMLElement>(null);
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!open) return undefined;

    const previousFocus = document.activeElement as HTMLElement | null;
    const previousOverflow = document.body.style.overflow;
    const focusableSelector =
      'button:not([disabled]), a[href], input:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';
    document.body.style.overflow = "hidden";

    const focusFirst = globalThis.setTimeout(() => {
      const preferredFocus = sheetRef.current?.querySelector<HTMLElement>(
        "[data-sheet-autofocus]",
      );
      (
        preferredFocus ??
        sheetRef.current?.querySelector<HTMLElement>(focusableSelector)
      )?.focus();
    }, 0);
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        onCloseRef.current();
        return;
      }
      if (event.key !== "Tab") return;
      const focusable = [
        ...(sheetRef.current?.querySelectorAll<HTMLElement>(
          focusableSelector,
        ) ?? []),
      ];
      if (focusable.length === 0) {
        event.preventDefault();
        return;
      }
      const first = focusable[0];
      const last = focusable.at(-1);
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last?.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first?.focus();
      }
    };

    globalThis.addEventListener("keydown", handleKeyDown);
    return () => {
      globalThis.clearTimeout(focusFirst);
      globalThis.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = previousOverflow;
      previousFocus?.focus();
    };
  }, [open]);

  if (!open) return null;

  return (
    <div className="ds-sheet-layer">
      <button
        className="ds-sheet-layer__backdrop"
        type="button"
        aria-label="메뉴 닫기"
        onClick={onClose}
      />
      <section
        ref={sheetRef}
        className="ds-sheet"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
      >
        <span className="ds-sheet__handle" aria-hidden="true" />
        <header className="ds-sheet__header">
          <h2 className="type-headline-medium" id={titleId}>
            {title}
          </h2>
          <Button variant="ghost" aria-label={closeLabel} onClick={onClose}>
            닫기
          </Button>
        </header>
        <div className="ds-sheet__content">{children}</div>
      </section>
    </div>
  );
}

interface ToastProps {
  actionLabel?: string;
  message: string;
  onAction?: () => void;
  tone?: "info" | "success" | "error";
}

export function Toast({
  actionLabel,
  message,
  onAction,
  tone = "info",
}: ToastProps) {
  return (
    <div
      className={`ds-toast ds-toast--${tone}`}
      role={tone === "error" ? "alert" : "status"}
    >
      <span>{message}</span>
      {actionLabel === undefined ? null : (
        <button type="button" onClick={onAction}>
          {actionLabel}
        </button>
      )}
    </div>
  );
}

interface ListItemProps {
  description?: string;
  leading?: ReactNode;
  onClick?: () => void;
  title: string;
  trailing?: ReactNode;
}

export function ListItem({
  description,
  leading,
  onClick,
  title,
  trailing,
}: ListItemProps) {
  const content = (
    <>
      {leading === undefined ? null : (
        <span className="ds-list-item__leading" aria-hidden="true">
          {leading}
        </span>
      )}
      <span className="ds-list-item__copy">
        <strong>{title}</strong>
        {description === undefined ? null : <span>{description}</span>}
      </span>
      {trailing === undefined ? null : (
        <span className="ds-list-item__trailing">{trailing}</span>
      )}
    </>
  );

  return onClick === undefined ? (
    <div className="ds-list-item">{content}</div>
  ) : (
    <button className="ds-list-item ds-list-item--button" onClick={onClick}>
      {content}
    </button>
  );
}

interface MoreButtonProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "children"
> {
  label: string;
}

/** Compact overflow action used by catalog and production list rows. */
export function MoreButton({
  className = "",
  label,
  ...props
}: MoreButtonProps) {
  return (
    <button
      className={`ds-more-button ${className}`.trim()}
      type="button"
      aria-label={label}
      {...props}
    >
      <span aria-hidden="true">•••</span>
    </button>
  );
}

interface ToggleSwitchProps {
  checked: boolean;
  disabled?: boolean;
  label: string;
  onChange: (checked: boolean) => void;
}

/** The single switch implementation used by catalog previews and app screens. */
export function ToggleSwitch({
  checked,
  disabled = false,
  label,
  onChange,
}: ToggleSwitchProps) {
  return (
    <label className="ds-switch">
      <span className="visually-hidden">{label}</span>
      <input
        type="checkbox"
        checked={checked}
        disabled={disabled}
        onChange={(event) => onChange(event.target.checked)}
      />
      <span aria-hidden="true" />
    </label>
  );
}

interface ChoiceOption<T extends string> {
  label: string;
  value: T;
}

interface ChoiceRowProps<T extends string> {
  compact?: boolean;
  label: string;
  onChange: (value: T) => void;
  options: ReadonlyArray<ChoiceOption<T>>;
  value: T;
}

/** Horizontally scrollable single-choice control from `/app/catalog/`. */
export function ChoiceRow<T extends string>({
  compact = false,
  label,
  onChange,
  options,
  value,
}: ChoiceRowProps<T>) {
  return (
    <div
      className={`ds-choice-row${compact ? " ds-choice-row--compact" : ""}`}
      aria-label={label}
    >
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          aria-pressed={value === option.value}
          onClick={() => onChange(option.value)}
        >
          {compact ? <span>{option.label}</span> : option.label}
        </button>
      ))}
    </div>
  );
}

interface FlatListRowProps {
  actions?: ReactNode;
  description?: ReactNode;
  detail?: ReactNode;
  element?: "article" | "li";
  meta?: ReactNode;
  onClick?: () => void;
  onLongPress?: () => void;
  status?: ReactNode;
  title: ReactNode;
  titleAs?: "strong" | "h2" | "h3";
}

/** Border-only list row shared by catalog previews and production lists. */
export function FlatListRow({
  actions,
  description,
  detail,
  element = "article",
  meta,
  onClick,
  onLongPress,
  status,
  title,
  titleAs = "strong",
}: FlatListRowProps) {
  const Root = element as ElementType;
  const Title = titleAs as ElementType;
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | undefined>(
    undefined,
  );
  const clearLongPress = () => {
    if (longPressTimer.current === undefined) return;
    clearTimeout(longPressTimer.current);
    longPressTimer.current = undefined;
  };
  const startLongPress = () => {
    if (onLongPress === undefined) return;
    clearLongPress();
    longPressTimer.current = setTimeout(() => {
      longPressTimer.current = undefined;
      onLongPress();
    }, 550);
  };
  const copy = (
    <>
      <Title>{title}</Title>
      {description === undefined ? null : <span>{description}</span>}
      {detail === undefined ? null : <span>{detail}</span>}
      {meta === undefined ? null : <small>{meta}</small>}
      {status === undefined ? null : (
        <span className="ds-list-row__status">{status}</span>
      )}
    </>
  );

  return (
    <Root
      className="ds-list-row"
      onPointerDown={startLongPress}
      onPointerUp={clearLongPress}
      onPointerCancel={clearLongPress}
      onPointerLeave={clearLongPress}
      onContextMenu={(event: React.MouseEvent) => {
        if (onLongPress === undefined) return;
        event.preventDefault();
        clearLongPress();
        onLongPress();
      }}
    >
      {onClick === undefined ? (
        <div className="ds-list-row__main">{copy}</div>
      ) : (
        <button className="ds-list-row__main" type="button" onClick={onClick}>
          {copy}
        </button>
      )}
      {actions === undefined ? null : (
        <div className="ds-list-row__actions">{actions}</div>
      )}
    </Root>
  );
}

interface SettingsGroupProps extends PropsWithChildren {
  title: string;
}

export function SettingsGroup({ children, title }: SettingsGroupProps) {
  return (
    <section className="ds-settings-group">
      <h2>{title}</h2>
      <div>{children}</div>
    </section>
  );
}

interface SettingsRowProps extends Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "children"
> {
  detail?: ReactNode;
  label: ReactNode;
}

export function SettingsRow({
  className = "",
  detail,
  label,
  onClick,
  ...props
}: SettingsRowProps) {
  if (onClick === undefined) {
    return (
      <div className={`ds-settings-row ${className}`.trim()}>
        <span>{label}</span>
        {detail === undefined ? null : <small>{detail}</small>}
      </div>
    );
  }
  return (
    <button
      className={`ds-settings-row ${className}`.trim()}
      type="button"
      onClick={onClick}
      {...props}
    >
      <span>{label}</span>
      {detail === undefined ? null : <small>{detail}</small>}
    </button>
  );
}

interface EmptyStateProps {
  actionLabel?: string;
  description: string;
  icon?: ReactNode;
  onAction?: () => void;
  title: string;
}

export function EmptyState({
  actionLabel,
  description,
  icon = "⌖",
  onAction,
  title,
}: EmptyStateProps) {
  return (
    <section className="ds-empty-state">
      <span className="ds-empty-state__icon" aria-hidden="true">
        {icon}
      </span>
      <h3 className="type-headline-small">{title}</h3>
      <p className="type-body-medium">{description}</p>
      {actionLabel === undefined ? null : (
        <Button onClick={onAction}>{actionLabel}</Button>
      )}
    </section>
  );
}

interface LoadingStateProps {
  label?: string;
  rows?: number;
}

export function LoadingState({
  label = "콘텐츠를 불러오는 중",
  rows = 3,
}: LoadingStateProps) {
  return (
    <div className="ds-loading-state" role="status" aria-label={label}>
      <span className="visually-hidden">{label}</span>
      {Array.from({ length: rows }, (_, index) => (
        <span
          className="ds-loading-state__row"
          key={index}
          aria-hidden="true"
        />
      ))}
    </div>
  );
}
