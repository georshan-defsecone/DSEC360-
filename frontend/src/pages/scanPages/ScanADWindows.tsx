import { Button } from "@/components/ui/button";
import { useState } from "react";
import { useForm, FormProvider} from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { FormInput, FormSelect, FormCheckbox } from "../../components/formComponents/form";
import { Card, CardContent } from "@/components/ui/card";
import Breadcrumbs from "@/components/ui/Breadcrumbs";
import {
    assetDiscoverySchema,
    type assetDiscoveryFields,
    defaultValues,
} from "../../components/formComponents/formSchema";
import Header from "../../components/Header";
import Sidebar from "../../components/Sidebar";

const assetDiscoveryMethodOptions = [
    { label: "Remote", value: "remote" },
    { label: "Upload", value: "upload" },
];

const scheduleFrequencyOptions = [
    { label: "Daily", value: "daily" },
    { label: "Weekly", value: "weekly" },
    { label: "Monthly", value: "monthly" },
    { label: "Yearly", value: "yearly" },
];

const timezoneOptions = [
    { label: "IST", value: "ist" },
    { label: "UTC", value: "utc" },
    { label: "EST", value: "est" },
    { label: "PST", value: "pst" },
];

function ScanADWindows() {
    const [page, setPage] = useState(1);

    const methods = useForm<assetDiscoveryFields>({
        resolver: zodResolver(assetDiscoverySchema),
        defaultValues,
        mode: "onBlur"
    });

    const formPages = [
        "●",
        "●",
        "●",
        "●",
    ];

    const onSubmit = async (data: assetDiscoveryFields) => {
        await new Promise((resolve) => setTimeout(resolve, 1000));
        alert(JSON.stringify(data, null, 2));
    };
    const assetDiscoveryMethod = methods.watch("assetDiscoveryMethod");
    const schedule = methods.watch("schedule");
    const notification = methods.watch("notification");

    const page1 = () => {
        return (
            <>
                <FormInput
                    name="projectName"
                    placeholder="Project Name"
                    label="Enter Project Name"
                />
                <FormInput
                    name="scanName"
                    placeholder="Scan Name"
                    label="Enter Scan Name"
                />
                <FormInput
                    name="scanDescription"
                    placeholder="Scan Description"
                    label="Enter Scan Description"
                />
            </>
        );
    };

    const page2 = () => {
        return (
            <>
                <FormSelect
                    name="assetDiscoveryMethod"
                    placeholder="Pick an asset discovery method"
                    label="Pick asset discovery method"
                    options={assetDiscoveryMethodOptions}
                />
                {assetDiscoveryMethod === "upload" && (
                    <>
                        <Button type="button">Upload</Button>
                    </>
                )}
                {assetDiscoveryMethod === "remote" && (
                    <>
                        <FormInput
                            name="username"
                            placeholder="john doe"
                            label="Username"
                        />
                        <FormInput name="password" label="Password" />
                        <FormInput
                            name="domain"
                            placeholder="Domain"
                            label="Domain"
                        />
                        <FormInput name="ipAddress" label="IP Address" />
                        <FormInput name="serverIP" label="Server IP" />
                    </>
                )}
            </>
        );
    };

    const page3 = () => {
        return (
            <>
                <FormCheckbox name="schedule" label="Schedule" />
                {schedule && (
                    <>
                        <FormSelect
                            name="scheduleFrequency"
                            placeholder="Frequency"
                            options={scheduleFrequencyOptions}
                            label="Schedule Frequency"
                        />
                        <FormInput
                            name="startDate"
                            type="date"
                            label="Start Date"
                        />
                        <FormInput
                            name="startTime"
                            type="time"
                            label="Start Time"
                        />
                        <FormSelect
                            name="timeZone"
                            placeholder="Timezone"
                            options={timezoneOptions}
                            label="Timezone"
                        />
                    </>
                )}
                <FormCheckbox name="notification" label="Notification" />
                {notification && (
                    <>
                        <FormInput
                            name="email"
                            type="email"
                            label="Email"
                            placeholder="email@email.com"
                        />
                    </>
                )}
            </>
        );
    };

    const renderPage = () => {
        switch (page) {
            case 1:
                return (
                    <div className="space-y-4">
                        <h2 className="text-xl font-semibold">
                            General Information
                        </h2>
                        {page1()}
                    </div>
                );

            case 2:
                return (
                    <div className="space-y-4">
                        <h2 className="text-xl font-semibold">
                            Target Details
                        </h2>
                        {page2()}
                    </div>
                );
            case 3:
                return (
                    <div className="space-y-4">
                        <h2 className="text-xl font-semibold">
                            Scheduling Scan
                        </h2>
                        {page3()}
                    </div>
                );
        }
    };

    const getFieldsForPage3 =  async () => {
        const fieldsToValidate: (keyof assetDiscoveryFields)[] = ["schedule", "notification"]
        if(methods.getValues("schedule")) {
            fieldsToValidate.push(
                "scheduleFrequency",
                "startDate",
                "startTime",
                "timeZone"
            );
        }
        if(methods.getValues("notification")) {
            fieldsToValidate.push(
                "email"
            );
        }
        return await methods.trigger(fieldsToValidate)
    }

    const getFieldsForPage2 = async () => {
        if (assetDiscoveryMethod === "remote") {
            return await methods.trigger([
                "username",
                "password",
                "ipAddress",
                "serverIP",
            ]);
        }
        return true;
    };

    const validateCurrentPage = async () => {
        switch (page) {
            case 1:
                return await methods.trigger([
                    "scanName",
                    "projectName",
                ]);
            case 2:
                return await getFieldsForPage2();
            case 3:
                return await getFieldsForPage3();
            default:
                return true;
        }
    };

    const nextPage = async () => {
        if (page < 3) {
            const isCurrentPageValid = await validateCurrentPage();
            if (isCurrentPageValid) {
                setPage((prev) => prev + 1);
            }
        }
    };

    const prevPage = () => {
        if (page > 1) {
            setPage((prev) => prev - 1);
        }
    };

    return (
        <>
            <div className="flex h-screen text-black">
                <Sidebar scanSettings={true} settings={false} homeSettings={false}/>
                <div className="flex-1 flex flex-col pr-8 pl-8 ml-64 pt-20">
                    <Header title="Asset Discovery" />
                    <div className="w-full flex justify-left items-center">
                        <Card className="w-[70%] mt-10 ml-4 shadow-2xl">
                            <CardContent className="w-full p-4 px-12">
                                <div className="w-auto space-y-6">
                                    <FormProvider {...methods}>
                                        <form>
                                            {renderPage()}
                                            <div className="flex justify-between mt-6">
                                                <button
                                                    type="button"
                                                    onClick={prevPage}
                                                    className={`px-4 py-2 rounded ${
                                                        page === 1
                                                            ? "bg-gray-300"
                                                            : "bg-black text-white"
                                                    }`}
                                                    disabled={page === 1}
                                                >
                                                    Previous
                                                </button>
                                                <Breadcrumbs
                                                    currentPage={page}
                                                    pages={formPages}
                                                />
                                                {page === 3 ? (
                                                    <button type="button" className="px-4 py-2 bg-black text-white" onClick={async () => {
                                                        const isValid = await validateCurrentPage()
                                                        if(isValid) {
                                                            methods.handleSubmit(onSubmit)()
                                                        }
                                                    }}>
                                                        Submit
                                                    </button>
                                                ) : (
                                                    <button
                                                        type="button"
                                                        onClick={nextPage}
                                                        className="px-4 py-2 bg-black w-25 text-white rounded"
                                                    >
                                                        Next
                                                    </button>
                                                )}
                                            </div>
                                        </form>
                                    </FormProvider>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                </div>
            </div>
        </>
    );
}

export default ScanADWindows;
