"use client";

import { useCallback, useEffect, useState } from "react";
import { useTranslations } from "next-intl";
import { createApiClient } from "@app/lib/api";
import { useEnvContext } from "@app/hooks/useEnvContext";
import { useToast } from "@app/hooks/useToast";
import { formatAxiosError } from "@app/lib/api";
import { Button } from "@app/components/ui/button";
import { Textarea } from "@app/components/ui/textarea";
import { Badge } from "@app/components/ui/badge";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle
} from "@app/components/ui/dialog";
import {
    SettingsSection,
    SettingsSectionBody,
    SettingsSectionFooter,
    SettingsSectionHeader,
    SettingsSectionTitle
} from "@app/components/Settings";

type DomainCertUploadProps = {
    orgId: string;
    domainId: string;
};

/**
 * OSS PEM upload for Cloudflare Origin / BYO certs.
 * Extracted from DomainCertForm so domain settings stay scannable.
 */
export default function DomainCertUpload({
    orgId,
    domainId
}: DomainCertUploadProps) {
    const t = useTranslations();
    const api = createApiClient(useEnvContext());
    const { toast } = useToast();
    const [uploadLoading, setUploadLoading] = useState(false);
    const [certContent, setCertContent] = useState("");
    const [keyContent, setKeyContent] = useState("");
    const [localCertStatus, setLocalCertStatus] = useState<
        "valid" | "none" | "unknown"
    >("unknown");
    const [localCertUpdated, setLocalCertUpdated] = useState<string | null>(
        null
    );
    const [overwriteOpen, setOverwriteOpen] = useState(false);

    const refreshLocalCert = useCallback(async () => {
        try {
            const res = await api.get(
                `/org/${orgId}/domain/${domainId}/certificate/local`
            );
            const data = res.data?.data;
            setLocalCertStatus(data?.status === "valid" ? "valid" : "none");
            setLocalCertUpdated(data?.lastUpdate ?? null);
        } catch {
            setLocalCertStatus("unknown");
        }
    }, [api, orgId, domainId]);

    useEffect(() => {
        void refreshLocalCert();
    }, [refreshLocalCert]);

    const doUpload = async () => {
        setUploadLoading(true);
        try {
            await api.post(`/org/${orgId}/domain/${domainId}/certificate/upload`, {
                certFile: certContent,
                keyFile: keyContent
            });
            toast({
                title: t("success"),
                description: t("certificateUploaded", {
                    fallback: "Certificate uploaded successfully"
                })
            });
            setCertContent("");
            setKeyContent("");
            setOverwriteOpen(false);
            await refreshLocalCert();
        } catch (error) {
            toast({
                title: t("error"),
                description: formatAxiosError(error),
                variant: "destructive"
            });
        } finally {
            setUploadLoading(false);
        }
    };

    const onUploadClick = () => {
        if (localCertStatus === "valid") {
            setOverwriteOpen(true);
        } else {
            void doUpload();
        }
    };

    return (
        <>
            <SettingsSection>
                <SettingsSectionHeader>
                    <SettingsSectionTitle>
                        {t("customCertificate", {
                            fallback: "Custom Certificate"
                        })}
                    </SettingsSectionTitle>
                </SettingsSectionHeader>
                <SettingsSectionBody>
                    <div className="flex items-center gap-2 text-sm">
                        <span className="text-muted-foreground">
                            {t("localCertificateStatus", {
                                fallback: "On-disk certificate"
                            })}
                            :
                        </span>
                        {localCertStatus === "valid" ? (
                            <Badge variant="green">
                                {t("valid", { fallback: "Valid" })}
                            </Badge>
                        ) : localCertStatus === "none" ? (
                            <Badge variant="outline">
                                {t("none", { fallback: "None" })}
                            </Badge>
                        ) : (
                            <Badge variant="yellow">
                                {t("unknown", { fallback: "Unknown" })}
                            </Badge>
                        )}
                        {localCertUpdated && (
                            <span className="text-xs text-muted-foreground">
                                {localCertUpdated}
                            </span>
                        )}
                    </div>
                    <p className="text-sm text-muted-foreground">
                        {t("customCertificateDescription", {
                            fallback:
                                "Upload a PEM certificate and private key (e.g. Cloudflare Origin Certificate). Files are written under traefik.certificates_path and picked up by Traefik."
                        })}
                    </p>
                    <div className="space-y-2">
                        <label className="text-sm font-medium">
                            {t("certificatePem", {
                                fallback: "Certificate (PEM)"
                            })}
                        </label>
                        <Textarea
                            value={certContent}
                            onChange={(e) => setCertContent(e.target.value)}
                            placeholder="-----BEGIN CERTIFICATE-----"
                            className="font-mono text-xs min-h-[120px]"
                        />
                    </div>
                    <div className="space-y-2">
                        <label className="text-sm font-medium">
                            {t("privateKeyPem", {
                                fallback: "Private Key (PEM)"
                            })}
                        </label>
                        <Textarea
                            value={keyContent}
                            onChange={(e) => setKeyContent(e.target.value)}
                            placeholder="-----BEGIN PRIVATE KEY-----"
                            className="font-mono text-xs min-h-[120px]"
                        />
                    </div>
                </SettingsSectionBody>
                <SettingsSectionFooter>
                    <Button
                        type="button"
                        onClick={onUploadClick}
                        loading={uploadLoading}
                        disabled={
                            !certContent.trim() ||
                            !keyContent.trim() ||
                            uploadLoading
                        }
                    >
                        {t("uploadCertificate", {
                            fallback: "Upload Certificate"
                        })}
                    </Button>
                </SettingsSectionFooter>
            </SettingsSection>

            <Dialog open={overwriteOpen} onOpenChange={setOverwriteOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>
                            {t("overwriteCertificate", {
                                fallback: "Overwrite certificate?"
                            })}
                        </DialogTitle>
                        <DialogDescription>
                            {t("overwriteCertificateDescription", {
                                fallback:
                                    "A custom certificate already exists for this domain. Uploading will replace it."
                            })}
                        </DialogDescription>
                    </DialogHeader>
                    <DialogFooter>
                        <Button
                            variant="outline"
                            onClick={() => setOverwriteOpen(false)}
                            disabled={uploadLoading}
                        >
                            {t("cancel", { fallback: "Cancel" })}
                        </Button>
                        <Button
                            onClick={() => void doUpload()}
                            loading={uploadLoading}
                            disabled={uploadLoading}
                        >
                            {t("overwrite", { fallback: "Overwrite" })}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </>
    );
}
