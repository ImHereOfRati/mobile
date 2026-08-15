import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { Button, LoadingState, TextField } from "@/design-system";

export function DeviceContactEditScreen({ contactId }: { contactId?: string }) {
  const bridge = useBridge();
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    let cancelled = false;
    void bridge
      .getDeviceContacts()
      .then((contacts) => {
        if (cancelled) return;
        const contact = contacts.find((item) => item.id === contactId);
        if (contact === undefined) {
          setError("연락처를 찾을 수 없습니다.");
          return;
        }
        setName(contact.displayName);
        setPhone(contact.phoneNumbers.join(", "));
      })
      .catch(() => {
        if (!cancelled) setError("연락처를 불러오지 못했습니다.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [bridge, contactId]);

  async function save() {
    const displayName = name.trim();
    if (!contactId || !displayName) {
      setError("닉네임을 입력해 주세요.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      await bridge.updateDeviceContact({ id: contactId, displayName });
      navigate("/friend", { replace: true });
    } catch {
      setError("닉네임을 저장하지 못했습니다.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="feature-page" data-clarity-mask="true">
      <header className="feature-page__header">
        <h1>기기 연락처 닉네임 수정</h1>
      </header>
      {loading ? (
        <LoadingState label="연락처를 불러오는 중입니다." rows={2} />
      ) : error && !name ? (
        <p className="feature-page__error" role="alert">{error}</p>
      ) : (
        <form
          className="feature-form"
          onSubmit={(event) => {
            event.preventDefault();
            void save();
          }}
        >
          <TextField label="닉네임" value={name} onChange={(event) => setName(event.target.value)} />
          <TextField label="전화번호" value={phone} readOnly />
          {error ? <p className="feature-page__error" role="alert">{error}</p> : null}
          <div className="feature-page__actions">
            <Button type="submit" loading={saving}>저장</Button>
            <Button type="button" variant="secondary" onClick={() => navigate(-1)}>취소</Button>
          </div>
        </form>
      )}
    </main>
  );
}
