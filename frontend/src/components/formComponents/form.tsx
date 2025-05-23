import { Input } from "@/components/ui/input";
import { useFormContext } from "react-hook-form";
import { Checkbox } from "@/components/ui/checkbox";
import { ErrorMessage } from "@hookform/error-message";

import { 
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue } from "@/components/ui/select";

interface FormInputProps {
    name: string;
    label: string;
    placeholder?: string;
    type?: "text" | "password" | "email" | "date" | "time" | "number";
}

interface FormSelectProps {
    name: string;
    label: string;
    placeholder: string;
    options: {value: string; label: string}[];
}

interface FormCheckboxProps {
    name: string;
    label: string;
}

export const FormInput = ({name, label, placeholder, type = "text"} : FormInputProps) => {
    const {register, formState: {errors}, watch} = useFormContext()
    const value = watch(name);
    console.log(name, "value: ", value, " error: ", errors[name])
    return(
            <div className="flex items-center">
                <p className="block w-70">{label}</p>
                <Input
                {...register(name)}
                type={type}
                placeholder={placeholder}
                className="w-80 mr-4"
                />
                <ErrorMessage errors={errors} name={name} render={({ message }) => <p className="text-red-600">{message}</p>}/>
            </div>
    )
}

export const FormSelect = ({name, label, placeholder, options}: FormSelectProps) => {
    const {setValue, watch, register, formState: {errors}} = useFormContext()
    const value = watch(name)

    register(name)

    return (
        <div className="flex items-center">
            <p className="block w-70 ">{label}</p>
            <Select
              value = {value || ""}
              onValueChange = {(newValue:string) => setValue(name, newValue, {shouldValidate: true})}
            >
                <SelectTrigger className="mr-4">
                    <SelectValue placeholder={placeholder}>{value || {placeholder}}</SelectValue>
                </SelectTrigger>

                <SelectContent>
                    {options.map((option) => (
                        <SelectItem key = {option.value} value={option.value}> {option.label} </SelectItem>
                    ))}
                </SelectContent>

            </Select>
            <ErrorMessage errors={errors} name={name} render={({ message }) => <p className="text-red-600">{message}</p>}/>
        </div>
    )
}

export const FormCheckbox = ({name, label}: FormCheckboxProps) => {
    const {watch, register, setValue} = useFormContext()
    register(name) 
    const value = watch(name)
    return(
        <div className="flex items-center gap-2">
            <Checkbox
              checked={value}
              onCheckedChange = {(checked:boolean) => {setValue(name, checked === true, {shouldValidate: true})}}
            />
            <p>{label}</p>
        </div>
    )
}