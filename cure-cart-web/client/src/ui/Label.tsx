import * as LabelPrimitive from '@radix-ui/react-label'
import { cn } from '../lib/utils'

export function Label({ className, ...props }: LabelPrimitive.LabelProps) {
  return <LabelPrimitive.Root className={cn('text-sm font-medium text-slate-700', className)} {...props} />
}









