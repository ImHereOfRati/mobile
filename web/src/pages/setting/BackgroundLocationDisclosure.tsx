import { BottomSheet, Button } from "@/design-system";

interface BackgroundLocationDisclosureProps {
  onClose: () => void;
  onConfirm: () => void;
  open: boolean;
}

const title =
  "\ubc31\uadf8\ub77c\uc6b4\ub4dc \uc704\uce58 \uc0ac\uc6a9 \uc548\ub0b4";
const description =
  "ImHere\ub294 \uc571\uc774 \ub2eb\ud600 \uc788\uac70\ub098 \uc0ac\uc6a9\ud558\uc9c0 \uc54a\ub294 \ub3d9\uc548\uc5d0\ub3c4 \uc124\uc815\ud55c \uc7a5\uc18c\uc758 \ub3c4\ucc29\u00b7\uc774\ud0c8\uc744 \uac10\uc9c0\ud558\uace0 \uc790\ub3d9 \uc54c\ub9bc\uc744 \ubcf4\ub0b4\uae30 \uc704\ud574 \uc704\uce58 \uc815\ubcf4\ub97c \uc0ac\uc6a9\ud569\ub2c8\ub2e4. \uc774 \uae30\ub2a5\uc744 \uc0ac\uc6a9\ud558\ub824\uba74 \ubc31\uadf8\ub77c\uc6b4\ub4dc \uc704\uce58 \uad8c\ud55c\uc774 \ud544\uc694\ud569\ub2c8\ub2e4.";
const confirmLabel =
  "\ub0b4\uc6a9\uc744 \ud655\uc778\ud588\uace0 \uad8c\ud55c \uc124\uc815 \uc5f4\uae30";

export function BackgroundLocationDisclosure({
  onClose,
  onConfirm,
  open,
}: BackgroundLocationDisclosureProps) {
  return (
    <BottomSheet open={open} title={title} onClose={onClose}>
      <div className="feature-page__sheet-actions">
        <p className="setting-note">{description}</p>
        <Button onClick={onConfirm}>{confirmLabel}</Button>
        <Button variant="secondary" onClick={onClose}>
          {"\ucde8\uc18c"}
        </Button>
      </div>
    </BottomSheet>
  );
}
