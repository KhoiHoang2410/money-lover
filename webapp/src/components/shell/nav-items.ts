import {
  ArrowLeftRight,
  LayoutDashboard,
  Mail,
  Scale,
  Settings,
  Target,
  TrendingUp,
  Wallet,
  type LucideIcon,
} from "lucide-react";

/*
 * The app's information architecture (PRD IA; issue 03). One ordered list drives
 * the sidebar, the icon-rail, and the mobile drawer. `key` resolves the label
 * via t(`nav.${key}`) — no copy is hard-coded here. `end` marks exact-match
 * routes (the Dashboard root) so the active state doesn't bleed onto children.
 */
export interface NavItem {
  key: string;
  to: string;
  icon: LucideIcon;
  end?: boolean;
}

export const NAV_ITEMS: readonly NavItem[] = [
  { key: "dashboard", to: "/", icon: LayoutDashboard, end: true },
  { key: "sources", to: "/sources", icon: Wallet },
  { key: "transactions", to: "/transactions", icon: ArrowLeftRight },
  { key: "envelopes", to: "/envelopes", icon: Mail },
  { key: "goals", to: "/goals", icon: Target },
  { key: "reports", to: "/reports", icon: TrendingUp },
  { key: "reconcile", to: "/reconcile", icon: Scale },
  { key: "settings", to: "/settings", icon: Settings },
];
