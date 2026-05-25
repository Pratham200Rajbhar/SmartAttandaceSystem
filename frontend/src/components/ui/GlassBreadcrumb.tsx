"use client";

import React from "react";
import Link from "next/link";
import { ChevronRight } from "lucide-react";

interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface GlassBreadcrumbProps {
  items: BreadcrumbItem[];
}

export default function GlassBreadcrumb({ items }: GlassBreadcrumbProps): React.ReactElement {
  return (
    <nav aria-label="Breadcrumb" className="mb-6">
      <ol className="breadcrumb">
        {items.map((item, i) => (
          <React.Fragment key={i}>
            {i > 0 && <ChevronRight size={12} className="breadcrumb-separator" />}
            <li>
              {item.href ? (
                <Link href={item.href} className="breadcrumb-item hover:underline">
                  {item.label}
                </Link>
              ) : (
                <span className="breadcrumb-item-active">{item.label}</span>
              )}
            </li>
          </React.Fragment>
        ))}
      </ol>
    </nav>
  );
}
