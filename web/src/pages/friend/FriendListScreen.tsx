import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { ApiHttpError } from "@/api/api-client";
import { useApiClient } from "@/api/use-api-client";
import { useBridge } from "@/bridge/bridge-context";
import { BottomSheet, Button, FlatListRow, MoreButton } from "@/design-system";
import { notificationService } from "@/pages/record/notification-service";

import {
  groupFriends,
  mergeFriends,
  type Friendship,
  type UnifiedFriend,
} from "./friend-model";
import { FriendFinder } from "./FriendAddScreen";
import { friendService } from "./friend-service";
import { InfiniteLoadButton } from "./InfiniteLoadButton";

interface FriendListScreenProps {
  finderInitiallyOpen?: boolean;
}

export function FriendListScreen({
  finderInitiallyOpen = false,
}: FriendListScreenProps) {
  const api = useApiClient();
  const bridge = useBridge();
  const navigate = useNavigate();
  const [relationships, setRelationships] = useState<Friendship[]>([]);
  const [contacts, setContacts] = useState<
    Awaited<ReturnType<typeof bridge.getDeviceContacts>>
  >([]);
  const [hasNext, setHasNext] = useState(false);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [finderOpen, setFinderOpen] = useState(finderInitiallyOpen);
  const [actionTarget, setActionTarget] = useState<
    Extract<UnifiedFriend, { kind: "server" }> | undefined
  >();
  const [contactTarget, setContactTarget] = useState<
    Extract<UnifiedFriend, { kind: "device" }> | undefined
  >();
  const [actionDetail, setActionDetail] = useState<Friendship>();

  // 목록은 페이지를 넘기며 오래 살아 있어서, 다른 기기에서 별명이 바뀌면
  // 화면의 값이 낡는다. 시트를 열 때 그 한 건만 서버에서 다시 읽는다.
  const openActions = async (
    item: Extract<UnifiedFriend, { kind: "server" }>,
  ) => {
    setActionTarget(item);
    setActionDetail(undefined);
    try {
      setActionDetail(
        await friendService.friendship(api, item.relationship.id),
      );
    } catch {
      setActionDetail(item.relationship);
    }
  };

  const load = async (nextPage: number, append = false, attempt = 0) => {
    setError("");
    try {
      if (nextPage === 0 && attempt === 0) {
        await bridge.getAuthState().catch(() => undefined);
      }
      const [friendResult, contactsResult] = await Promise.allSettled([
        Promise.resolve().then(() => friendService.list(api, nextPage)),
        nextPage === 0
          ? Promise.resolve().then(() => bridge.getDeviceContacts())
          : Promise.resolve(contacts),
      ]);
      if (friendResult.status === "rejected") {
        // Some API deployments use 404 for an account with no friendships.
        // Treat that response as an empty list instead of a load failure.
        if (
          !(friendResult.reason instanceof ApiHttpError) ||
          friendResult.reason.status !== 404
        ) {
          throw friendResult.reason;
        }
      }
      const friendPage =
        friendResult.status === "fulfilled"
          ? {
              content: Array.isArray(friendResult.value?.content)
                ? friendResult.value.content
                : [],
              hasNext: friendResult.value?.hasNext === true,
            }
          : { content: [], hasNext: false };
      setRelationships((current) =>
        append ? [...current, ...friendPage.content] : friendPage.content,
      );
      if (nextPage === 0 && contactsResult.status === "fulfilled") {
        setContacts(contactsResult.value);
      }
      setPage(nextPage);
      setHasNext(friendPage.hasNext);
    } catch {
      if (attempt < 1) {
        // On Android the WebView can mount just before Flutter finishes
        // restoring the access token. Retry once so the first friend screen
        // load does not turn that short bridge/auth race into a hard error.
        await new Promise((resolve) => window.setTimeout(resolve, 1000));
        return load(nextPage, append, attempt + 1);
      }
      setError("친구 목록을 불러오지 못했습니다.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void Promise.resolve().then(() => load(0));
    // The first request is intentionally bound to the current bridge/API pair.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, bridge]);

  const groups = useMemo(
    () => groupFriends(mergeFriends(relationships, contacts)),
    [contacts, relationships],
  );

  // 서버가 클라이언트에게 허용하는 발송 타입은 위치 관련 세 가지뿐이다.
  // 자동 전송이 막혔거나 지금 바로 알리고 싶을 때 쓰는 수동 경로다.
  const notifyArrival = async (
    item: Extract<UnifiedFriend, { kind: "server" }>,
  ) => {
    setActionTarget(undefined);
    try {
      await notificationService.send(api, {
        notificationMethod: "FCM",
        targetIds: [item.relationship.friend.id],
        type: "ARRIVAL",
      });
      setError("");
    } catch {
      setError("도착 알림을 보내지 못했습니다.");
    }
  };

  const mutateRelationship = async (
    item: Extract<UnifiedFriend, { kind: "server" }>,
    action: "alias" | "delete" | "block",
  ) => {
    try {
      if (action === "alias") {
        const alias = window
          .prompt("새 별명을 입력하세요.", item.displayName)
          ?.trim();
        if (!alias) return;
        const updated = await friendService.updateAlias(
          api,
          item.relationship.id,
          alias,
        );
        setRelationships((current) =>
          current.map((value) => (value.id === updated.id ? updated : value)),
        );
        return;
      }
      await (action === "delete"
        ? friendService.delete(api, item.relationship.id)
        : friendService.block(api, item.relationship.friend.id));
      setRelationships((current) =>
        current.filter((value) => value.id !== item.relationship.id),
      );
    } catch {
      setError("친구 정보를 변경하지 못했습니다.");
    }
  };

  const mutateDeviceContact = async (
    item: Extract<UnifiedFriend, { kind: "device" }>,
    action: "alias" | "delete",
  ) => {
    try {
      if (action === "alias") {
        navigate(`/friend/device-contact/${item.contact.id}/edit`);
        return;
      }
      await bridge.deleteDeviceContact({ id: item.contact.id });
      setContacts((current) =>
        current.filter((contact) => contact.id !== item.contact.id),
      );
    } catch {
      setError("기기 연락처를 변경하지 못했습니다.");
    }
  };

  return (
    <main className="feature-page" data-clarity-mask="true">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">연락처</span>
          <h1>친구</h1>
          <p>ImHere 친구와 기기 연락처를 한곳에서 확인하세요.</p>
        </div>
      </header>

      <nav aria-label="친구 관리" className="feature-page__actions">
        <Button onClick={() => setFinderOpen(true)}>친구 추가</Button>
        <Link className="ds-button ds-button--secondary" to="/friend/requests">
          받은 요청
        </Link>
        <Link
          className="ds-button ds-button--secondary"
          to="/friend/restrictions"
        >
          친구 관리
        </Link>
      </nav>

      {error && (
        <p className="feature-page__error" role="alert">
          {error}
        </p>
      )}
      {loading ? (
        <p aria-live="polite">친구 목록을 불러오는 중입니다.</p>
      ) : groups.size === 0 ? (
        <section className="feature-page__list-card">
          <h2>아직 등록된 친구가 없어요</h2>
          <p>닉네임이나 이메일로 친구를 찾아 요청을 보내보세요.</p>
        </section>
      ) : (
        [...groups].map(([group, items]) => (
          <section aria-labelledby={`friend-group-${group}`} key={group}>
            <h2 id={`friend-group-${group}`}>{group}</h2>
            <ul className="feature-page__list">
              {items.map((item) => (
                <FlatListRow
                  element="li"
                  key={item.id}
                  title={item.displayName}
                  titleAs="h3"
                  onLongPress={
                    item.kind === "device"
                      ? () => setContactTarget(item)
                      : undefined
                  }
                  description={`${item.description || "전화번호 없음"} · ${
                    item.kind === "server" ? "ImHere 친구" : "기기 연락처"
                  }`}
                  actions={
                    item.kind === "server" ? (
                      <MoreButton
                        aria-label={`${item.displayName} 더보기`}
                        label={`${item.displayName} 더보기`}
                        onClick={() => void openActions(item)}
                      />
                    ) : (
                      <MoreButton
                        aria-label={`${item.displayName} 연락처 더보기`}
                        label={`${item.displayName} 연락처 더보기`}
                        onClick={() => setContactTarget(item)}
                      />
                    )
                  }
                />
              ))}
            </ul>
          </section>
        ))
      )}
      <InfiniteLoadButton
        hasNext={hasNext}
        label="친구 더 보기"
        load={() => load(page + 1, true)}
      />
      <BottomSheet
        open={finderOpen}
        title="친구 찾기"
        onClose={() => setFinderOpen(false)}
      >
        <FriendFinder
          onContactSelected={(contact) =>
            setContacts((current) =>
              current.some((item) => item.id === contact.id)
                ? current
                : [...current, contact],
            )
          }
        />
      </BottomSheet>
      <BottomSheet
        open={contactTarget !== undefined}
        title={contactTarget?.displayName ?? "기기 연락처"}
        onClose={() => setContactTarget(undefined)}
      >
        <div className="feature-page__sheet-actions">
          <Button
            variant="secondary"
            onClick={() => {
              if (contactTarget === undefined) return;
              const target = contactTarget;
              setContactTarget(undefined);
              void mutateDeviceContact(target, "alias");
            }}
          >
            닉네임 수정
          </Button>
          <Button
            variant="danger"
            onClick={() => {
              if (contactTarget === undefined) return;
              const target = contactTarget;
              setContactTarget(undefined);
              void mutateDeviceContact(target, "delete");
            }}
          >
            삭제
          </Button>
        </div>
      </BottomSheet>
      <BottomSheet
        open={actionTarget !== undefined}
        title={actionTarget?.displayName ?? ""}
        onClose={() => {
          setActionTarget(undefined);
          setActionDetail(undefined);
        }}
      >
        {actionDetail?.friend && (
          <p className="setting-note">
            {`${actionDetail.friend.nickname} · ${actionDetail.friend.email}`}
            <br />
            {`${actionDetail.createdAt?.slice(0, 10) ?? "-"}부터 친구`}
            {actionDetail.friendAlias && ` · 별명 ${actionDetail.friendAlias}`}
          </p>
        )}
        <div className="feature-page__sheet-actions">
          <Button
            onClick={() => {
              if (actionTarget === undefined) return;
              void notifyArrival(actionTarget);
            }}
          >
            도착 알림 보내기
          </Button>
          <Button
            variant="secondary"
            onClick={() => {
              if (actionTarget === undefined) return;
              const target = actionTarget;
              setActionTarget(undefined);
              void mutateRelationship(target, "alias");
            }}
          >
            별명 수정
          </Button>
          <Button
            variant="danger"
            onClick={() => {
              if (actionTarget === undefined) return;
              const target = actionTarget;
              setActionTarget(undefined);
              void mutateRelationship(target, "delete");
            }}
          >
            삭제
          </Button>
          <Button
            variant="danger"
            onClick={() => {
              if (actionTarget === undefined) return;
              const target = actionTarget;
              setActionTarget(undefined);
              void mutateRelationship(target, "block");
            }}
          >
            차단
          </Button>
        </div>
      </BottomSheet>
    </main>
  );
}
