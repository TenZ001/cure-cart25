import { Slot } from '@radix-ui/react-slot'
import { cn } from '../lib/utils'
import { ButtonHTMLAttributes, forwardRef } from 'react'

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  asChild?: boolean
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
}

const base = 'inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none'
const variants: Record<string, string> = {
  primary: 'bg-brand-primary text-white hover:bg-brand-primary/90 focus-visible:ring-brand-primary',
  secondary: 'bg-white text-slate-900 border border-slate-200 hover:bg-slate-50 focus-visible:ring-slate-300',
  ghost: 'text-slate-700 hover:bg-slate-100',
}
const sizes: Record<string, string> = {
  sm: 'h-9 px-3 text-sm',
  md: 'h-10 px-4 text-sm',
  lg: 'h-11 px-6 text-base',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className, asChild, variant = 'primary', size = 'md', ...props },
  ref,
) {
  const Comp: any = asChild ? Slot : 'button'
  return (
    <Comp ref={ref} className={cn(base, variants[variant], sizes[size], className)} {...props} />
  )
})









