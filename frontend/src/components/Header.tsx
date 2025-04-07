import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"


export default function Header() {
    return (
      <header className="w-full px-6 py-10 flex justify-between items-center">
        <div className="text-xl font-semibold">DashBoard</div>
        <Avatar>
            <AvatarImage src="https://github.com/shadcn.png" />
            <AvatarFallback>CN</AvatarFallback>
        </Avatar>

      </header>
    )
  }
  