import Link from "next/link";

export default function HomePage() {
  return (
    <main className="max-w-7xl mx-auto px-6 py-10">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-semibold">
          NOTEShub
        </h1>
        <p className="text-sm text-muted-foreground mt-1">
          All the best for your studies!
          Pick a semester below to get started with notes and resources.
        </p>
      </div>

      {/* Semesters */}
      <section>
        <h2 className="text-lg font-medium mb-4">
          Semesters
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Locked */}
          <SemesterCard
            title="Semester 1"
            locked
          />
          <SemesterCard
            title="Semester 2"
            locked
          />
          <SemesterCard
            title="Semester 3"
            locked
          />

          {/* Active */}
          <Link href="/semester/4">
            <SemesterCard
              title="Semester 4"
              active
            />
          </Link>
        </div>
      </section>
    </main>
  );
}

function SemesterCard({
  title,
  locked,
  active,
}: {
  title: string;
  locked?: boolean;
  active?: boolean;
}) {
  return (
    <div
      className={`rounded-lg border p-4 transition cursor-pointer
        ${
          active
            ? "border-blue-500 bg-blue-500/5"
            : "border-border bg-background"
        }
        ${locked ? "opacity-50 cursor-not-allowed" : "hover:border-foreground/30"}
      `}
    >
      <div className="font-medium">{title}</div>

      <div className="text-xs text-muted-foreground mt-1">
        {locked && "Locked"}
        {active && "Active semester"}
      </div>
    </div>
  );
}
