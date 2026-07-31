"use client";

import UptimeAlertSection from "@app/components/UptimeAlertSection";

import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import {
    Form,
    FormControl,
    FormDescription,
    FormField,
    FormItem,
    FormLabel,
    FormMessage
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { useSiteContext } from "@app/hooks/useSiteContext";
import { useForm } from "react-hook-form";
import { toast, useToast } from "@app/hooks/useToast";
import { useRouter } from "next/navigation";
import {
    SettingsContainer,
    SettingsFormCell,
    SettingsFormGrid,
    SettingsSection,
    SettingsSectionHeader,
    SettingsSectionTitle,
    SettingsSectionDescription,
    SettingsSectionBody,
    SettingsSectionForm,
    SettingsSectionFooter
} from "@app/components/Settings";
import { formatAxiosError } from "@app/lib/api";
import { createApiClient } from "@app/lib/api";
import { useEnvContext } from "@app/hooks/useEnvContext";
import { useState } from "react";
import { SwitchInput } from "@app/components/SwitchInput";
import { ExternalLink } from "lucide-react";
import { useTranslations } from "next-intl";
import { useOrgContext } from "@app/hooks/useOrgContext";
import { usePaidStatus } from "@app/hooks/usePaidStatus";
import { tierMatrix, TierFeature } from "@server/lib/billing/tierMatrix";
import { Button as ButtonUI } from "@/components/ui/button";
import { PaidFeaturesAlert } from "@app/components/PaidFeaturesAlert";

const GeneralFormSchema = z.object({
    name: z.string().nonempty("Name is required"),
    niceId: z.string().min(1).max(255).optional(),
    dockerSocketEnabled: z.boolean().optional(),
    autoUpdateEnabled: z.boolean().optional(),
    autoUpdateOverrideOrg: z.boolean().optional(),
    // pangolin-plus: WireGuard tunnel profile (edit existing sites)
    tunnelProfile: z
        .enum([
            "standard",
            "secure-vpn",
            "split-tunnel",
            "privacy-gateway"
        ])
        .optional(),
    routingMode: z.enum(["full-tunnel", "selective"]).optional()
});

type GeneralFormValues = z.infer<typeof GeneralFormSchema>;

export default function GeneralPage() {
    const { site, updateSite } = useSiteContext();
    const { org } = useOrgContext();

    const { env } = useEnvContext();
    const api = createApiClient(useEnvContext());
    const router = useRouter();
    const t = useTranslations();
    const { toast } = useToast();
    const { isPaidUser } = usePaidStatus();
    const hasAutoUpdateFeature = isPaidUser(
        tierMatrix[TierFeature.NewtAutoUpdate]
    );

    const [loading, setLoading] = useState(false);
    const [activeCidrTagIndex, setActiveCidrTagIndex] = useState<number | null>(
        null
    );

    const orgAutoUpdate = org.org.settingsEnableGlobalNewtAutoUpdate ?? false;

    const form = useForm({
        resolver: zodResolver(GeneralFormSchema),
        defaultValues: {
            name: site?.name,
            niceId: site?.niceId || "",
            dockerSocketEnabled: site?.dockerSocketEnabled ?? false,
            autoUpdateEnabled: site?.autoUpdateOverrideOrg
                ? (site?.autoUpdateEnabled ?? false)
                : orgAutoUpdate,
            autoUpdateOverrideOrg: site?.autoUpdateOverrideOrg ?? false,
            tunnelProfile: (site?.tunnelProfile ??
                "standard") as GeneralFormValues["tunnelProfile"],
            routingMode: (site?.routingMode ??
                "selective") as GeneralFormValues["routingMode"]
        },
        mode: "onChange"
    });

    async function onSubmit(data: GeneralFormValues) {
        setLoading(true);

        try {
            const tunnelProfile =
                data.tunnelProfile ?? ("standard" as const);
            const routingMode = data.routingMode ?? ("selective" as const);

            const body: {
                name: string;
                niceId?: string;
                dockerSocketEnabled?: boolean;
                autoUpdateEnabled?: boolean;
                autoUpdateOverrideOrg?: boolean;
                tunnelProfile?: GeneralFormValues["tunnelProfile"];
                routingMode?: GeneralFormValues["routingMode"];
            } = {
                name: data.name,
                niceId: data.niceId,
                dockerSocketEnabled: data.dockerSocketEnabled,
                autoUpdateEnabled: data.autoUpdateEnabled,
                autoUpdateOverrideOrg: data.autoUpdateOverrideOrg
            };
            if (site?.type === "wireguard") {
                body.tunnelProfile = tunnelProfile;
                body.routingMode = routingMode;
            }

            await api.post(`/site/${site?.siteId}`, body);

            updateSite({
                name: data.name,
                niceId: data.niceId,
                dockerSocketEnabled: data.dockerSocketEnabled,
                autoUpdateEnabled: data.autoUpdateEnabled,
                autoUpdateOverrideOrg: data.autoUpdateOverrideOrg,
                ...(site?.type === "wireguard"
                    ? {
                          tunnelProfile,
                          routingMode
                      }
                    : {})
            });

            if (data.niceId && data.niceId !== site?.niceId) {
                router.replace(
                    `/${site?.orgId}/settings/sites/${data.niceId}/general`
                );
            }

            toast({
                title: t("siteUpdated"),
                description: t("siteUpdatedDescription")
            });
        } catch (e) {
            toast({
                variant: "destructive",
                title: t("siteErrorUpdate"),
                description: formatAxiosError(
                    e,
                    t("siteErrorUpdateDescription")
                )
            });
        }

        setLoading(false);

        router.refresh();
    }

    return (
        <SettingsContainer>
            {site?.siteId && site?.orgId && site.type != "local" && (
                <UptimeAlertSection
                    orgId={site.orgId}
                    siteId={site.siteId}
                    startingName={site.name}
                />
            )}
            <SettingsSection>
                <SettingsSectionHeader>
                    <SettingsSectionTitle>
                        {t("generalSettings")}
                    </SettingsSectionTitle>
                    <SettingsSectionDescription>
                        {t("siteGeneralDescription")}
                    </SettingsSectionDescription>
                </SettingsSectionHeader>

                <SettingsSectionBody>
                    <SettingsSectionForm variant="half">
                        <Form {...form}>
                            <form
                                onSubmit={form.handleSubmit(onSubmit)}
                                className="space-y-6"
                                id="general-settings-form"
                            >
                                <SettingsFormGrid>
                                    <SettingsFormCell span="half">
                                        <FormField
                                            control={form.control}
                                            name="name"
                                            render={({ field }) => (
                                                <FormItem>
                                                    <FormLabel>
                                                        {t("name")}
                                                    </FormLabel>
                                                    <FormControl>
                                                        <Input {...field} />
                                                    </FormControl>
                                                    <FormMessage />
                                                </FormItem>
                                            )}
                                        />
                                    </SettingsFormCell>
                                    <SettingsFormCell span="half">
                                        <FormField
                                            control={form.control}
                                            name="niceId"
                                            render={({ field }) => (
                                                <FormItem>
                                                    <FormLabel>
                                                        {t("identifier")}
                                                    </FormLabel>
                                                    <FormControl>
                                                        <Input
                                                            {...field}
                                                            placeholder={t(
                                                                "enterIdentifier"
                                                            )}
                                                        />
                                                    </FormControl>
                                                    <FormMessage />
                                                </FormItem>
                                            )}
                                        />
                                    </SettingsFormCell>
                                </SettingsFormGrid>

                                {site && site.type === "newt" && (
                                    <FormField
                                        control={form.control}
                                        name="dockerSocketEnabled"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormControl>
                                                    <SwitchInput
                                                        id="docker-socket-enabled"
                                                        label={t(
                                                            "enableDockerSocket"
                                                        )}
                                                        defaultChecked={
                                                            field.value
                                                        }
                                                        onCheckedChange={
                                                            field.onChange
                                                        }
                                                    />
                                                </FormControl>
                                                <FormMessage />
                                                <FormDescription>
                                                    {t.rich(
                                                        "enableDockerSocketDescription",
                                                        {
                                                            docsLink: (
                                                                chunks
                                                            ) => (
                                                                <a
                                                                    href="https://docs.pangolin.net/manage/sites/configure-site#docker-socket-integration"
                                                                    target="_blank"
                                                                    rel="noopener noreferrer"
                                                                    className="text-primary hover:underline inline-flex items-center gap-1"
                                                                >
                                                                    {chunks}
                                                                    <ExternalLink className="size-3.5 shrink-0" />
                                                                </a>
                                                            )
                                                        }
                                                    )}
                                                </FormDescription>
                                            </FormItem>
                                        )}
                                    />
                                )}

                                {/* pangolin-plus: edit WireGuard tunnel profile on existing sites */}
                                {site && site.type === "wireguard" && (
                                    <div className="space-y-4">
                                        <FormField
                                            control={form.control}
                                            name="tunnelProfile"
                                            render={({ field }) => (
                                                <FormItem>
                                                    <FormLabel>
                                                        {t("tunnelProfile", {
                                                            fallback:
                                                                "Tunnel Profile"
                                                        })}
                                                    </FormLabel>
                                                    <FormControl>
                                                        <select
                                                            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                                                            value={
                                                                field.value ||
                                                                "standard"
                                                            }
                                                            onChange={(e) => {
                                                                const profile =
                                                                    e.target
                                                                        .value as
                                                                        | "standard"
                                                                        | "secure-vpn"
                                                                        | "split-tunnel"
                                                                        | "privacy-gateway";
                                                                field.onChange(
                                                                    profile
                                                                );
                                                                // Keep routingMode in sync with profile defaults
                                                                if (
                                                                    profile ===
                                                                        "secure-vpn" ||
                                                                    profile ===
                                                                        "privacy-gateway"
                                                                ) {
                                                                    form.setValue(
                                                                        "routingMode",
                                                                        "full-tunnel"
                                                                    );
                                                                } else {
                                                                    form.setValue(
                                                                        "routingMode",
                                                                        "selective"
                                                                    );
                                                                }
                                                            }}
                                                        >
                                                            <option value="standard">
                                                                {t(
                                                                    "tunnelProfileStandard",
                                                                    {
                                                                        fallback:
                                                                            "Standard (selective)"
                                                                    }
                                                                )}
                                                            </option>
                                                            <option value="secure-vpn">
                                                                {t(
                                                                    "tunnelProfileSecureVpn",
                                                                    {
                                                                        fallback:
                                                                            "Secure VPN (full tunnel)"
                                                                    }
                                                                )}
                                                            </option>
                                                            <option value="split-tunnel">
                                                                {t(
                                                                    "tunnelProfileSplitTunnel",
                                                                    {
                                                                        fallback:
                                                                            "Split Tunnel (targets only)"
                                                                    }
                                                                )}
                                                            </option>
                                                            <option value="privacy-gateway">
                                                                {t(
                                                                    "tunnelProfilePrivacyGateway",
                                                                    {
                                                                        fallback:
                                                                            "Privacy Gateway (full tunnel + edge DNS)"
                                                                    }
                                                                )}
                                                            </option>
                                                        </select>
                                                    </FormControl>
                                                    <FormDescription>
                                                        {t(
                                                            "tunnelProfileDescription",
                                                            {
                                                                fallback:
                                                                    "Presets set routing mode. Secure VPN and Privacy Gateway route all traffic; Split Tunnel only reaches site targets."
                                                            }
                                                        )}
                                                    </FormDescription>
                                                    <FormMessage />
                                                </FormItem>
                                            )}
                                        />
                                        <FormField
                                            control={form.control}
                                            name="routingMode"
                                            render={({ field }) => (
                                                <FormItem>
                                                    <FormLabel>
                                                        {t("routingMode", {
                                                            fallback:
                                                                "Routing Mode"
                                                        })}
                                                    </FormLabel>
                                                    <FormControl>
                                                        <select
                                                            className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                                                            value={
                                                                field.value ||
                                                                "selective"
                                                            }
                                                            onChange={(e) =>
                                                                field.onChange(
                                                                    e.target
                                                                        .value
                                                                )
                                                            }
                                                        >
                                                            <option value="selective">
                                                                {t(
                                                                    "routingModeSelective",
                                                                    {
                                                                        fallback:
                                                                            "Selective (targets only)"
                                                                    }
                                                                )}
                                                            </option>
                                                            <option value="full-tunnel">
                                                                {t(
                                                                    "routingModeFullTunnel",
                                                                    {
                                                                        fallback:
                                                                            "Full Tunnel (0.0.0.0/0)"
                                                                    }
                                                                )}
                                                            </option>
                                                        </select>
                                                    </FormControl>
                                                    <FormDescription>
                                                        {t(
                                                            "routingModeDescription",
                                                            {
                                                                fallback:
                                                                    "Controls WireGuard peer AllowedIPs on the exit node. Changing this refreshes the Gerbil peer."
                                                            }
                                                        )}
                                                    </FormDescription>
                                                    <FormMessage />
                                                </FormItem>
                                            )}
                                        />
                                    </div>
                                )}

                                <PaidFeaturesAlert
                                    tiers={tierMatrix.newtAutoUpdate}
                                />
                                {site &&
                                    site.type === "newt" &&
                                    !env.flags.disableEnterpriseFeatures && (
                                        <FormField
                                            control={form.control}
                                            name="autoUpdateEnabled"
                                            render={({ field }) => {
                                                const isOverriding = form.watch(
                                                    "autoUpdateOverrideOrg"
                                                );
                                                return (
                                                    <FormItem>
                                                        <FormControl>
                                                            <div className="">
                                                                <SwitchInput
                                                                    id="auto-update-enabled"
                                                                    label={t(
                                                                        "siteAutoUpdateLabel"
                                                                    )}
                                                                    checked={
                                                                        field.value
                                                                    }
                                                                    onCheckedChange={(
                                                                        checked
                                                                    ) => {
                                                                        field.onChange(
                                                                            checked
                                                                        );
                                                                        form.setValue(
                                                                            "autoUpdateOverrideOrg",
                                                                            true
                                                                        );
                                                                    }}
                                                                    disabled={
                                                                        !hasAutoUpdateFeature
                                                                    }
                                                                />
                                                                {isOverriding && (
                                                                    <ButtonUI
                                                                        type="button"
                                                                        variant="link"
                                                                        size="sm"
                                                                        className="text-sm text-muted-foreground px-0"
                                                                        onClick={() => {
                                                                            form.setValue(
                                                                                "autoUpdateOverrideOrg",
                                                                                false
                                                                            );
                                                                            form.setValue(
                                                                                "autoUpdateEnabled",
                                                                                orgAutoUpdate
                                                                            );
                                                                        }}
                                                                    >
                                                                        {t(
                                                                            "siteAutoUpdateResetToOrg"
                                                                        )}
                                                                    </ButtonUI>
                                                                )}
                                                            </div>
                                                        </FormControl>
                                                        <FormDescription>
                                                            {t(
                                                                "siteAutoUpdateDescription"
                                                            )}{" "}
                                                            <a
                                                                href="https://docs.pangolin.net/manage/sites/auto-update"
                                                                target="_blank"
                                                                rel="noopener noreferrer"
                                                                className="text-primary hover:underline inline-flex items-center gap-1"
                                                            >
                                                                {t("learnMore")}
                                                                <ExternalLink className="size-3.5 shrink-0" />
                                                            </a>
                                                        </FormDescription>
                                                        <FormMessage />
                                                    </FormItem>
                                                );
                                            }}
                                        />
                                    )}
                            </form>
                        </Form>
                    </SettingsSectionForm>
                </SettingsSectionBody>
                <SettingsSectionFooter>
                    <Button
                        type="submit"
                        form="general-settings-form"
                        loading={loading}
                        disabled={loading}
                    >
                        Save All Settings
                    </Button>
                </SettingsSectionFooter>
            </SettingsSection>
        </SettingsContainer>
    );
}
