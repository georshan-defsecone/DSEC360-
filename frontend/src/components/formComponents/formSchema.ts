import { z } from "zod";

const assetDiscoverySchema = z
    .object({
        // Page 1
        projectName: z.string().min(1, "Project name is required"),
        scanName: z.string().min(1, "Scan name is required"),
        scanDescription: z.string().optional(),

        // Page 2 - Shared
        assetDiscoveryMethod: z.enum(["remote", "upload"]),

        // Page 2 - Conditional fields - make them optional
        username: z.string().optional(),
        password: z.string().optional(),
        domain: z.string().optional(),
        ipAddress: z.string().optional(),
        serverIP: z.string().optional(),
        
        //page 3
        //scheduling stuff
        schedule: z.boolean(),
        scheduleFrequency: z
            .enum(["daily", "weekly", "monthly", "yearly"])
            .optional(),
        startDate: z.string().optional(),
        startTime: z.string().optional(),
        timeZone: z.enum(["ist", "utc", "est", "pst"]).optional(),

        //notification stuff
        notification: z.boolean(),
        email: z.string().email().optional(),
    })
    .superRefine((data, ctx) => {
        if (data.assetDiscoveryMethod === "remote") {
            if (!data.username || data.username.trim() === "")
                ctx.addIssue({
                    path: ["username"],
                    code: "custom",
                    message: "Username required",
                });
            if (!data.password || data.password.trim() === "")
                ctx.addIssue({
                    path: ["password"],
                    code: "custom",
                    message: "Password required",
                });
            if (!data.ipAddress || data.ipAddress.trim() === "")
                ctx.addIssue({
                    path: ["ipAddress"],
                    code: "custom",
                    message: "IP address required",
                });
            if (!data.serverIP || data.serverIP.trim() === "")
                ctx.addIssue({
                    path: ["serverIP"],
                    code: "custom",
                    message: "Server IP required",
                });
        }
        if (data.schedule) {
            if (!data.scheduleFrequency) {
                ctx.addIssue({
                    path: ["scheduleFrequency"],
                    code: z.ZodIssueCode.custom,
                    message: "Schedule frequency necessary",
                });
            }
            if (!data.startDate) {
                ctx.addIssue({
                    path: ["startDate"],
                    code: z.ZodIssueCode.custom,
                    message: "startDate necessary",
                });
            }
            if (!data.startTime) {
                ctx.addIssue({
                    path: ["startTime"],
                    code: z.ZodIssueCode.custom,
                    message: "startTime necessary",
                });
            }
            if (!data.timeZone) {
                ctx.addIssue({
                    path: ["timeZone"],
                    code: z.ZodIssueCode.custom,
                    message: "timeZone necessary",
                });
            }
        }
        if (data.notification) {
            if (!data.email) {
                ctx.addIssue({
                    path: ["email"],
                    code: z.ZodIssueCode.custom,
                    message: "email necessary",
                });
            }
        }
    });

// Use z.infer instead of z.output for better type inference
type assetDiscoveryFields = z.infer<typeof assetDiscoverySchema>;

type allAssetDiscoveryFields =
    | "projectName"
    | "scanName"
    | "scanDescription"
    | "username"
    | "password"
    | "ipAddress"
    | "domain"
    | "assetDiscoveryMethod"
    | "serverIP"
    | "schedule"
    | "scheduleFrequency"
    | "startTime"
    | "startDate"
    | "timeZone"
    | "notification"
    | "email";

const defaultValues: assetDiscoveryFields = {
    projectName: "",
    scanName: "",
    scanDescription: undefined,
    assetDiscoveryMethod: "remote",
    username: undefined,
    password: undefined,
    domain: undefined,
    ipAddress: undefined,
    serverIP: undefined,
    schedule: false,
    scheduleFrequency: undefined,
    startTime: undefined,
    startDate: undefined,
    timeZone: undefined,
    notification: false,
    email: undefined,
};

export { assetDiscoverySchema, type assetDiscoveryFields, defaultValues, type allAssetDiscoveryFields };