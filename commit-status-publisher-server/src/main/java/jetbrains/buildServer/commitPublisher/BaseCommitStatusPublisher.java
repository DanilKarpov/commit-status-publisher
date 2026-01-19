

/*
 * Copyright 2000-2024 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package jetbrains.buildServer.commitPublisher;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import jetbrains.buildServer.serverSide.*;
import jetbrains.buildServer.users.User;
import jetbrains.buildServer.util.StringUtil;
import jetbrains.buildServer.vcs.SVcsModification;
import jetbrains.buildServer.vcs.VcsRoot;
import org.apache.commons.lang.math.NumberUtils;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import static jetbrains.buildServer.commitPublisher.LoggerUtil.LOG;

public abstract class BaseCommitStatusPublisher implements CommitStatusPublisher {

  public static final int DEFAULT_CONNECTION_TIMEOUT = 10000;
  public static final String CONNECTION_TIMEOUT_PARAM = "commitStatusPublisher.connectionTimeout";
  protected final Map<String, String> myParams;
  private int myConnectionTimeout;
  protected CommitStatusPublisherProblems myProblems;
  protected SBuildType myBuildType;
  private final String myBuildFeatureId;
  private final CommitStatusPublisherSettings mySettings;
  private static final String BUILD_ID_URL_PARAM = "buildId=";

  protected BaseCommitStatusPublisher(@NotNull CommitStatusPublisherSettings settings,
                                      @NotNull SBuildType buildType,@NotNull String buildFeatureId,
                                      @NotNull Map<String, String> params,
                                      @NotNull CommitStatusPublisherProblems problems) {
    mySettings = settings;
    myParams = params;
    myProblems = problems;
    myBuildType = buildType;
    myBuildFeatureId = buildFeatureId;
    myConnectionTimeout = DEFAULT_CONNECTION_TIMEOUT;
    if (buildType instanceof BuildTypeEx) {
      String strTimeout = ((BuildTypeEx)buildType).getInternalParameterValue(CONNECTION_TIMEOUT_PARAM, "");
      if (!StringUtil.isEmpty(strTimeout)) {
        try {
          myConnectionTimeout = Integer.parseInt(strTimeout);
        } catch (NumberFormatException ex) {
          LOG.warnAndDebugDetails("Failure to parse connection timeout value " + strTimeout, ex);
        }
      }
    }
  }

  protected abstract WebLinks getLinks();

  public boolean buildQueued(@NotNull BuildPromotion buildPromotion, @NotNull BuildRevision revision, @NotNull AdditionalTaskInfo additionalTaskInfo) throws PublisherException {
    return false;
  }

  public boolean buildRemovedFromQueue(@NotNull BuildPromotion buildPromotion, @NotNull BuildRevision revision, @NotNull AdditionalTaskInfo additionalTaskInfo) throws PublisherException {
    return false;
  }

  public boolean buildStarted(@NotNull SBuild build, @NotNull BuildRevision revision) throws PublisherException {
    return false;
  }

  public boolean buildFinished(@NotNull SBuild build, @NotNull BuildRevision revision) throws PublisherException {
    return false;
  }

  public boolean buildCommented(@NotNull SBuild build, @NotNull BuildRevision revision, @Nullable User user, @Nullable String comment, boolean buildInProgress)
    throws PublisherException {
    return false;
  }

  public boolean buildInterrupted(@NotNull SBuild build, @NotNull BuildRevision revision) throws PublisherException {
    return false;
  }

  public boolean buildFailureDetected(@NotNull SBuild build, @NotNull BuildRevision revision) throws PublisherException {
    return false;
  }

  public boolean buildMarkedAsSuccessful(@NotNull SBuild build, @NotNull BuildRevision revision, boolean buildInProgress) throws PublisherException {
    return false;
  }

  protected int getConnectionTimeout() {
    return myConnectionTimeout;
  }

  public void setConnectionTimeout(int timeout) {
    myConnectionTimeout = timeout;
  }

  @NotNull
  @Override
  public Collection<BuildRevision> getFallbackRevisions(@Nullable SBuild build) {
    return Collections.emptyList();
  }

  @Override
  public boolean hasBuildFeature() {
    return true;
  }

  @Nullable
  public String getVcsRootId() {
    return myParams.get(Constants.VCS_ROOT_ID_PARAM);
  }

  @NotNull
  public CommitStatusPublisherSettings getSettings() {
    return mySettings;
  }

  public boolean isPublishingForRevision(@NotNull final BuildRevision revision) {
    VcsRoot vcsRoot = revision.getRoot();
    return getSettings().isPublishingForVcsRoot(vcsRoot);
  }

  public boolean isEventSupported(Event event) {
    return mySettings.isEventSupported(event, myBuildType, myParams);
  }

  @Override
  public boolean isAvailable(@NotNull BuildPromotion buildPromotion) {
    return !isPersonalBuildWithPatch(buildPromotion);
  }

  private boolean isPersonalBuildWithPatch(@NotNull BuildPromotion buildPromotion) {
    if (buildPromotion.isPersonal()) {
      for(SVcsModification change: buildPromotion.getPersonalChanges()) {
        if (change.isPersonal())
          return true;
      }
    }
    return false;
  }

  @NotNull
  public SBuildType getBuildType() { return myBuildType; }

  @NotNull
  public String getBuildFeatureId() { return myBuildFeatureId; }

  public CommitStatusPublisherProblems getProblems() {return myProblems; }

  @Override
  public RevisionStatus getRevisionStatus(@NotNull BuildPromotion buildPromotion, @NotNull BuildRevision revision) throws PublisherException {
    return null;
  }

  @Nullable
  protected String getViewUrl(@NotNull BuildPromotion buildPromotion) {
    SBuild build = buildPromotion.getAssociatedBuild();
    if (build != null) {
      return applyServerUrlOverride(getLinks().getViewResultsUrl(build));
    }
    SQueuedBuild queuedBuild = buildPromotion.getQueuedBuild();
    if (queuedBuild != null) {
      return applyServerUrlOverride(getLinks().getQueuedBuildUrl(queuedBuild));
    }
    return buildPromotion.getBuildType() != null ? applyServerUrlOverride(getLinks().getConfigurationHomePageUrl(buildPromotion.getBuildType())) : null;
  }

  @NotNull
  protected String getViewUrl(@NotNull SBuild build) {
    return applyServerUrlOverride(getLinks().getViewResultsUrl(build));
  }

  /**
   * Applies the server URL override if configured via internal property.
   * This allows replacing the default TeamCity server URL with a custom one
   * (e.g., when TeamCity is behind a proxy or has a different public URL).
   *
   * @param originalUrl the original URL from WebLinks
   * @return the URL with server part replaced if override is configured, otherwise the original URL
   */
  @Nullable
  protected String applyServerUrlOverride(@Nullable String originalUrl) {
    if (originalUrl == null) {
      return null;
    }

    String overrideServerUrl = TeamCityProperties.getPropertyOrNull(Constants.OVERRIDE_SERVER_URL_PROPERTY);
    if (StringUtil.isEmptyOrSpaces(overrideServerUrl)) {
      return originalUrl;
    }

    try {
      URL original = new URL(originalUrl);
      URL override = new URL(overrideServerUrl);

      // Build new URL with override host/port/protocol but original path and query
      StringBuilder newUrl = new StringBuilder();
      newUrl.append(override.getProtocol()).append("://").append(override.getHost());
      if (override.getPort() != -1 && override.getPort() != override.getDefaultPort()) {
        newUrl.append(":").append(override.getPort());
      }
      // Add override path prefix if present (e.g., /teamcity)
      String overridePath = override.getPath();
      if (!StringUtil.isEmptyOrSpaces(overridePath) && !"/".equals(overridePath)) {
        newUrl.append(overridePath);
      }
      // Add original path
      String originalPath = original.getPath();
      if (!StringUtil.isEmptyOrSpaces(originalPath)) {
        if (!originalPath.startsWith("/")) {
          newUrl.append("/");
        }
        newUrl.append(originalPath);
      }
      // Add original query if present
      if (original.getQuery() != null) {
        newUrl.append("?").append(original.getQuery());
      }

      LOG.debug("Applied server URL override: " + originalUrl + " -> " + newUrl);
      return newUrl.toString();
    } catch (MalformedURLException e) {
      LOG.warnAndDebugDetails("Failed to apply server URL override. Original URL: " + originalUrl + ", Override: " + overrideServerUrl, e);
      return originalUrl;
    }
  }

  protected Long getBuildIdFromViewUrl(@Nullable String url) {
    if (url == null) {
      return null;
    }
    int i = url.indexOf(BUILD_ID_URL_PARAM);
    StringBuilder idBuilder = new StringBuilder();
    if (i == -1) {
      i = url.length() - 1;
      while (i > 0 && Character.isDigit(url.charAt(i))) {
        idBuilder.append(url.charAt(i--));
      }
      idBuilder.reverse();
      if (i < 0 || url.charAt(i) != '/') {
        return null;
      }
    } else {
      i += BUILD_ID_URL_PARAM.length();

      while (i < url.length() && Character.isDigit(url.charAt(i))) {
        idBuilder.append(url.charAt(i++));
      }
    }

    Long buildId = NumberUtils.toLong(idBuilder.toString(), -1);
    return buildId == -1 ? null : buildId;
  }
}