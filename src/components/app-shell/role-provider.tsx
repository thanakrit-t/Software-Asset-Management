"use client";

import { createContext, useContext, useMemo } from "react";
import type { Viewer } from "@/features/auth/types";

interface ViewerContextValue {
  viewer: Viewer;
  role: Viewer["role"];
}

const ViewerContext = createContext<ViewerContextValue | null>(null);

export function RoleProvider({
  viewer,
  children,
}: {
  viewer: Viewer;
  children: React.ReactNode;
}) {
  const value = useMemo<ViewerContextValue>(
    () => ({ viewer, role: viewer.role }),
    [viewer],
  );

  return <ViewerContext.Provider value={value}>{children}</ViewerContext.Provider>;
}

function useViewerContext(): ViewerContextValue {
  const context = useContext(ViewerContext);
  if (!context) throw new Error("Viewer hooks must be used within RoleProvider");
  return context;
}

export function useViewer(): Viewer {
  return useViewerContext().viewer;
}

export function useRole(): Pick<ViewerContextValue, "role"> {
  const { role } = useViewerContext();
  return { role };
}