import { Input } from "@/components/ui/input";

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

type FormChangeHandler = (
  e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement> | string,
  field?: string
) => void;

interface ElevatePrivilegeFormProps {
  elevatePrivilege: string;
  formData: {
    EP_escalationAccount: string;
    EP_escalationPassword: string;
    EP_dzdoDirectory: string;
    EP_suDirectory: string;
    EP_pbrunDirectory: string;
    EP_su_sudoDirectory: string;
    EP_su_login: string;
    EP_su_user: string;
    EP_sudoUser: string;
    EPsshUserPassword: string;
    EPenablePassword: string;
  };
  handleInputChange: FormChangeHandler;
}

export const ElevatePrivilegeForm = ({
    elevatePrivilege,
  formData,
  handleInputChange,
}: ElevatePrivilegeFormProps) => {
    return (
        <div className="space-y-4">
          <div className="flex justify-start items-center mb-8">
            <p className="block w-70">Elevate privileges with</p>
            <Select
              value={elevatePrivilege}
              onValueChange={(value) =>
                handleInputChange(value, "elevatePrivilege")
              }
            >
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Elevate privilege" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="nothing">Nothing</SelectItem>
                <SelectItem value=".k5login">.k5login</SelectItem>
                <SelectItem value="ciscoEnable">Cisco 'enable'</SelectItem>
                <SelectItem value="dzdo">dzdo</SelectItem>
                <SelectItem value="su">su</SelectItem>
                <SelectItem value="pbrun">pbrun</SelectItem>
                <SelectItem value="su+sudo">su+sudo</SelectItem>
              </SelectContent>
            </Select>
          </div>
  
          {elevatePrivilege === ".k5login" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">Escalation Account:</p>
                <Input
                  type="text"
                  name="EP_escalationAccount"
                  placeholder="Enter escalation account"
                  value={formData.EP_escalationAccount}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
  
          {elevatePrivilege === "ciscoEnable" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">Enable Password:</p>
                <Input
                  type="password"
                  name="EPenablePassword"
                  placeholder="Enter enable password"
                  value={formData.EPenablePassword}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
  
          {elevatePrivilege === "dzdo" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">Escalation Account:</p>
                <Input
                  type="text"
                  name="EP_escalationAccount"
                  placeholder="Enter escalation account"
                  value={formData.EP_escalationAccount}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">Escalation Password:</p>
                <Input
                  type="password"
                  name="EP_escalationPassword"
                  placeholder="Enter escalation password"
                  value={formData.EP_escalationPassword}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">dzdo Directory:</p>
                <Input
                  type="text"
                  name="EP_dzdoDirectory"
                  placeholder="Enter dzdo directory"
                  value={formData.EP_dzdoDirectory}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
  
          {elevatePrivilege === "su" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">su Directory:</p>
                <Input
                  type="text"
                  name="EP_suDirectory"
                  placeholder="Enter su directory"
                  value={formData.EP_suDirectory}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">su Login:</p>
                <Input
                  type="text"
                  name="EP_su_login"
                  placeholder="Enter su login"
                  value={formData.EP_su_login}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">Escalation Password:</p>
                <Input
                  type="password"
                  name="EP_escalationPassword"
                  placeholder="Enter escalation password"
                  value={formData.EP_escalationPassword}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
  
          {elevatePrivilege === "pbrun" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">pbrun Directory:</p>
                <Input
                  type="text"
                  name="EP_pbrunDirectory"
                  placeholder="Enter pbrun directory"
                  value={formData.EP_pbrunDirectory}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">SSH User Password:</p>
                <Input
                  type="password"
                  name="EPsshUserPassword"
                  placeholder="Enter SSH user password"
                  value={formData.EPsshUserPassword}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
  
          {elevatePrivilege === "su+sudo" && (
            <div className="space-y-4 pl-4 border-l-2 border-gray-200">
              <div className="flex items-center">
                <p className="block w-70">su+sudo Directory:</p>
                <Input
                  type="text"
                  name="EP_su_sudoDirectory"
                  placeholder="Enter su+sudo directory"
                  value={formData.EP_su_sudoDirectory}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">su User:</p>
                <Input
                  type="text"
                  name="EP_su_user"
                  placeholder="Enter su user"
                  value={formData.EP_su_user}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">sudo User:</p>
                <Input
                  type="text"
                  name="EP_sudoUser"
                  placeholder="Enter sudo user"
                  value={formData.EP_sudoUser}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
              <div className="flex items-center">
                <p className="block w-70">Escalation Password:</p>
                <Input
                  type="password"
                  name="EP_escalationPassword"
                  placeholder="Enter escalation password"
                  value={formData.EP_escalationPassword}
                  onChange={handleInputChange}
                  className="w-80"
                  required
                />
              </div>
            </div>
          )}
        </div>
      );
}
