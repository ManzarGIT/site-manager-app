-- AlterTable
ALTER TABLE "Worker" ADD COLUMN     "contractAmount" DOUBLE PRECISION,
ADD COLUMN     "contractDescription" TEXT,
ADD COLUMN     "paymentType" TEXT NOT NULL DEFAULT 'DAILY_WAGE',
ADD COLUMN     "ratePerUnit" DOUBLE PRECISION,
ADD COLUMN     "taskDescription" TEXT,
ADD COLUMN     "unitDescription" TEXT,
ALTER COLUMN "wageRate" SET DEFAULT 0;

-- CreateTable
CREATE TABLE "WorkProgress" (
    "id" TEXT NOT NULL,
    "workerId" TEXT NOT NULL,
    "quantity" DOUBLE PRECISION NOT NULL,
    "description" TEXT,
    "recordedBy" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WorkProgress_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "WorkProgress" ADD CONSTRAINT "WorkProgress_workerId_fkey" FOREIGN KEY ("workerId") REFERENCES "Worker"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
