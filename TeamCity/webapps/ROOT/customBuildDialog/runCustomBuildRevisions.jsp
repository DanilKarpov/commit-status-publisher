<%@ page import="jetbrains.buildServer.serverSide.Branch" %>
<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<jsp:useBean id="runBuildBean" type="jetbrains.buildServer.controllers.RunBuildBean" scope="request"/>
<jsp:useBean id="dependenciesUI" class="jetbrains.buildServer.controllers.buildType.DependenciesUIBean"/>
<c:set var="branches" value="${runBuildBean.branches}"/>
<c:set var="hasBranches" value="${not empty branches}"/>
<c:set var="stateKeyParam" value="${util:urlEscape(param['stateKey'])}"/>
<c:set var="baseCustomBuildUrl" value="/runCustomBuild.html?buildTypeId=${runBuildBean.buildType.externalId}&stateKey=${stateKeyParam}&customBuildDialog=true"/>
<c:url value="${baseCustomBuildUrl}&updateChanges=true" var="url"/>
<c:set var="unspecifiedBranch" value="<%=Branch.UNSPECIFIED_BRANCH_NAME%>"/>
<c:set var="defaultBranch" value="<%=Branch.DEFAULT_BRANCH_NAME%>"/>
<c:set var="allowRevisionsCustomizationInAllModes" value="${intprop:getBoolean('teamcity.customBuildDialog.allowRevisionsCustomizationInAllModes')}"/>

<authz:authorize projectId="${runBuildBean.buildType.projectId}" allPermissions="CUSTOMIZE_BUILD_REVISIONS">
  <div id="changes-tab" style="display: none;" class="tabContent">
    <bs:refreshable containerId="changesContainer" pageUrl="${url}">
    <table class="runnerFormTable">
      <c:if test="${hasBranches}">
        <tr <c:if test='${not runBuildBean.defaultChangesSettings}'>class="modifiedParam"</c:if>>
          <td style="vertical-align: top;"><label for="branchFilter" style="white-space: nowrap; width: 8em;">Build branch:</label></td>
          <td style="vertical-align: top;">
            <input name="branchName" id="branchName_input" value="<c:out value='${runBuildBean.branchName}'/>" type="hidden"/>
            <span style="display: inline-block; width: 660px;"><span id="runBranchSelector_container"></span></span>
            <script>
              (function() {
                var name = '${util:forJS(runBuildBean.branchName, true, false)}';
                var defaultBranch = name === BS.Branch.DEFAULT_NAME;
                var selectedBranchExcluded = ${runBuildBean.selectedBranchExcluded};
                if (selectedBranchExcluded) {
                  BS.RunBuildDialog.highlightChanges('#runBranchSelector_container');
                  BS.RunBuildDialog.disableSubmit();
                }
                ReactUI.renderBranchSelect('runBranchSelector_container', {
                  projectOrBuildTypeNode: {
                    nodeType: 'bt',
                    id: '${runBuildBean.buildType.externalId}'
                  },
                  buildTypeInternalId: '${runBuildBean.buildType.internalId}',
                  includeUnspecified: ${not runBuildBean.buildType.defaultBranchExcluded},
                  excludeWildcard: true,
                  excludeGroups: true,
                  old: true,
                  oldFullWidth: true,
                  includeSnapshots: true,
                  special: true,
                  allowAny: true,
                  currentZindex: BS.Hider._currentZindex(),
                  selected: selectedBranchExcluded ? null : {
                    name: name,
                    default: defaultBranch,
                    unspecified: name === BS.Branch.UNSPECIFIED_NAME
                  },
                  onSelect: function(selected){
                    if (selected == null) return;

                    var branch = BS.Branch.stringifyBranch(selected);
                    $j('#branchName_input').val(branch);
                    BS.RunBuildDialog.updateChangesContainer('changesContainer', 'branchChanged').then(function() {
                      if (branch != undefined){
                        BS.RunBuildDialog.enableSubmit();
                      }
                    });
                    BS.RunBuildDialog.highlightChanges('#runBranchSelector_container');
                  }
                });
              })();
            </script>

            <forms:saving id="changesProgress" className="progressRingInline"/>

            <div class="attentionComment" id="couldNotFindBranchWarning" style="display: none;"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>TeamCity was not able to determine branch for the selected change. Please choose appropriate branch from the list.</div>
            <div class="attentionComment" id="wrongBranchForSelectedChange" style="display: none;"><bs:buildStatusIcon type="red-sign" className="warningIcon"/>The selected branch name does not correspond to the specified change, please check the branch name or change are correct.</div>

          </td>
        </tr>
      </c:if>
        <tr <c:if test='${not runBuildBean.defaultChangesSettings}'>class="modifiedParam"</c:if>>
          <td class="noBorder"><label for="modificationId" style="white-space: nowrap; width: 8em;">Include changes:</label></td>
          <td class="noBorder <c:if test="${runBuildBean.modificationIdSpecified}">modifiedParam</c:if>" style="padding-bottom: 0.5em;">
            <forms:select name="modificationId"
                          id="modificationId"
                          style="width: 47em;"
                          enableFilter="true" filterOptions="{monospace: true}">
              <c:if test="${not empty runBuildBean.dependencies.dependOnPromotionIds and dependenciesUI.softDependenciesEnabled or runBuildBean.modificationId == 'auto'}">
              <forms:option selected="${runBuildBean.modificationId == 'auto'}" value="auto">&lt;auto mode&gt;</forms:option>
              </c:if>
              <forms:option selected="${runBuildBean.modificationId == ''}" value="">&lt;latest changes at the moment the build is started&gt;</forms:option>
              <forms:option selected="${runBuildBean.modificationId == 'custom'}" value="custom">&lt;manually specified revisions></forms:option>
              <c:if test="${not empty runBuildBean.selectedChange}">
                <c:set var="vcsChange" value="${runBuildBean.selectedChange}"/>
                <c:set var="selectedChange" value="${vcsChange}"/>
                <%@include file="vcsChangeOption.jsp"%>
              </c:if>
              <forms:option disabled="true" className="unfilterable" value="loadingChanges">Loading changes<c:if test="${hasBranches}"> for the selected branch</c:if>, please wait...</forms:option>

            </forms:select> <forms:saving id="revisionsProgress" className="progressRingInline"/>
          </td>
        </tr>
      <c:if test="${runBuildBean.freezeSettingsAllowed}">
        <tr>
          <td class="noBorder">
            <label for="buildSettingsMode">Use settings:<bs:help file="Triggering+a+Custom+Build" anchor="UsesettingsfromVCS"/></label>
          </td>
          <td class="noBorder">
            <forms:select name="buildSettingsMode" enableFilter="true" onchange="BS.RunBuildDialog.highlightSettingRevisions();">
              <forms:option value="default" selected="${runBuildBean.buildSettingsMode == 'default'}"><c:out value="${runBuildBean.defaultBuildSettingsModeDescription}"/></forms:option>
              <forms:option value="current" selected="${runBuildBean.buildSettingsMode == 'current'}">current on TeamCity server</forms:option>
              <forms:option value="vcs" selected="${runBuildBean.buildSettingsMode == 'vcs'}">from VCS</forms:option>
            </forms:select>
          </td>
        </tr>
      </c:if>
        <tr>
          <td style="padding-bottom: 0.5em; border: 0;" colspan="2">
            <bs:refreshable containerId="revisionsContainer" pageUrl="${url}">
              <c:if test="${runBuildBean.modificationIdSpecified or runBuildBean.modificationId eq 'custom'}">
                <c:set var="revisionsInfo" value="${runBuildBean.revisions}"/>
                <c:set var="error" value="${revisionsInfo.error}"/>
                <c:choose>
                  <c:when test="${not empty error}">
                    <span class="error" style="margin-left: 0"><c:out value="${error.message}"/></span>
                  </c:when>
                  <c:otherwise>
                    <table class="settings" style="margin:10px 0; width:100%;">
                      <tr>
                        <th>VCS root</th>
                        <th>Build configuration</th>
                        <th colspan="2">Revision</th>
                      </tr>
                      <c:forEach items="${revisionsInfo.vcsRoots}" var="vcsRoot">
                        <c:set var="revisionsList" value="${revisionsInfo.revisions[vcsRoot]}"/>
                        <c:set var="numRevs" value="${fn:length(revisionsList)}"/>
                        <c:forEach items="${revisionsList}" var="revPair" varStatus="pos">
                          <c:set var="revision" value="${revPair.second}"/>
                          <tr>
                            <c:if test="${pos.first or numRevs < 2}">
                              <td style="width: 35%; vertical-align: top;" <c:if test="${numRevs > 1}">rowspan="${numRevs}"</c:if>>
                                <c:choose>
                                  <c:when test="${revision != null and revision.settingsRevision}">
                                    <span class="customDialogSettingsRevision">
                                      <i class="tc-icon icon16 tc-icon_cog" title="TeamCity settings revision"></i><bs:trimWithTooltip maxlength="45"><c:out value="${vcsRoot.name}"/></bs:trimWithTooltip>
                                    </span>
                                  </c:when>
                                  <c:otherwise>
                                    <bs:trimWithTooltip maxlength="45"><c:out value="${vcsRoot.name}"/></bs:trimWithTooltip>
                                  </c:otherwise>
                                </c:choose>
                              </td>
                            </c:if>
                            <td style="width: 35%">
                              <c:if test="${not empty revPair.first}">
                                <bs:buildTypeLinkFull buildType="${revPair.first}" contextProject="${runBuildBean.buildType.project}"/>
                              </c:if>
                            </td>
                            <td style="width: 25%; border-right: none">
                              <c:set var="controlName" value="revision:${vcsRoot.id}:${revPair.first.buildTypeId}"/>
                              <c:set var="controlId" value="revision_${vcsRoot.id}_${revPair.first.buildTypeId}"/>
                              <c:set var="vcsBranchName" value="${revision.repositoryVersion.vcsBranch == null ? '' : revision.repositoryVersion.vcsBranch}"/>
                              <c:choose>
                                <c:when test="${revision != null}">
                                  <c:set var="revisionControls">
                                    <span id="${controlId}_readOnly">
                                    <c:choose>
                                      <c:when test="${revision.modificationId ne null and revision.modificationId ge 0}">
                                        <c:url var="changeUrl" value="/viewModification.html?modId=${revision.modificationId}&personal=false&tab=vcsModificationFiles"/>
                                        <a href="${changeUrl}" target="_blank"><bs:trimWithTooltip maxlength="20">${revision.revisionDisplayName}</bs:trimWithTooltip></a>
                                      </c:when>
                                      <c:otherwise><bs:trimWithTooltip maxlength="20">${revision.revisionDisplayName}</bs:trimWithTooltip></c:otherwise>
                                    </c:choose>
                                    </span>
                                    <a href="#" onclick="BS.Util.hide('${controlId}_readOnly', this); BS.Util.show('${controlId}', '${controlId}_reset'); return false" style="color: #aaa">
                                    <c:if test="${allowRevisionsCustomizationInAllModes or revisionsInfo.vcsSettingsChanged[vcsRoot] or runBuildBean.modificationId == 'custom'}"><bs:svgIcon name="pencil"/></a></c:if>
                                    <c:set var="sanitizedBranchName"><bs:escapeForJs forHTMLAttribute="true" text="${vcsBranchName}"/></c:set>
                                    <forms:textField name="${controlName}" id="${controlId}" value="${revision.revision}" style="width: 13em; display: none"
                                                     onkeyup="{
                                                          BS.RunBuildDialog.enableSubmit();
                                                          if ($j('#${controlId}')[0].defaultValue == $j('#${controlId}').val()) return false;
                                                          BS.Util.hide('${controlId}_revisionCheck');
                                                          $j('#${controlId}_text').text('');
                                                          BS.Util.show('${controlId}_progress');
                                                          BS.RunBuildDialog.verifyRevision('${runBuildBean.buildType.externalId}', ${vcsRoot.id}, $j('#${controlId}').val(), '${sanitizedBranchName}', function(errCode, message) {
                                                            BS.Util.hide('${controlId}_progress');
                                                            if (errCode == 'revisionCantBeVerified' || message == '') return;
                                                            BS.Util.show('${controlId}_revisionCheck');
                                                            $j('#${controlId}_text').text(message);
                                                            if (errCode == 'revisionIsInvalid') {
                                                              BS.RunBuildDialog.disableSubmit()
                                                            }
                                                          });
                                                          return false; }"/>
                                    <forms:progressRing id="${controlId}_progress" style="display: none;" progressTitle="Verifying revision"/>
                                    <c:if test="${revisionsInfo.vcsSettingsChanged[vcsRoot]}">*</c:if>
                                    <div id="${controlId}_revisionCheck" style="display: none"><i class="tc-icon icon16 tc-icon_attention tc-icon_attention_yellow"></i><span id="${controlId}_text"></span></div>
                                  </c:set>
                                  <c:choose>
                                    <c:when test="${revision.settingsRevision}">
                                      <span class="customDialogSettingsRevision">${revisionControls}</span>
                                    </c:when>
                                    <c:otherwise>
                                      ${revisionControls}
                                    </c:otherwise>
                                  </c:choose>
                                </c:when>
                                <c:otherwise>
                                  <em>revision not found, will omit sources</em>
                                </c:otherwise>
                              </c:choose>
                            </td>
                            <td style="width: 5%">
                              <a id="${controlId}_reset" href="#" onclick="$j('#${controlId}').val($j('#${controlId}')[0].defaultValue); BS.Util.hide('${controlId}_revisionCheck'); $j('#${controlId}_text').text(''); BS.Util.hide('${controlId}_progress'); BS.RunBuildDialog.enableSubmit();" style="display: none">Reset</a>
                            </td>
                          </tr>
                        </c:forEach>
                      </c:forEach>
                    </table>
                    <c:if test="${not empty revisionsInfo.vcsSettingsChanged}">
                      <div class="note">
                        * Note: VCS settings (VCS roots or checkout rules) of the build configuration might have changed since the selected change,
                        however TeamCity will use current VCS settings for the build.
                      </div>
                    </c:if>
                  </c:otherwise>
                </c:choose>
              </c:if>

              <script type="text/javascript">
                BS.Util.hide('couldNotFindBranchWarning');
                BS.Util.hide('wrongBranchForSelectedChange');
              <c:if test="${runBuildBean.showUnspecifiedBranchWarning}">
                BS.Util.show('couldNotFindBranchWarning');
              </c:if>
              <c:if test="${runBuildBean.showIncorrectBranchWarning}">
                BS.Util.show('wrongBranchForSelectedChange');
              </c:if>
              </script>
            </bs:refreshable>
          </td>
        </tr>
      <c:if test="${not hasBranches and runBuildBean.selectedBranchExcluded}">
        <tr>
          <td colspan="2">
            <div class="attentionComment">
              <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Builds in the <c:out value="${empty runBuildBean.branchName ? 'default' : runBuildBean.branchName}"/> branch are disabled and build configuration doesn't have any other branches.
              If you run a build, it will fail.
            </div>
          </td>
        </tr>
      </c:if>
    </table>
    <div id="changesOptions" style="display: none"></div>
    <script type="text/javascript">
      (function($) {

        BS.ajaxUpdater('changesOptions', '<c:url value="${baseCustomBuildUrl}&changes=true"/>', {
          method: 'get',
          evalScripts: true,
          onComplete: function() {
            BS.RunBuildDialog.enableSubmit();
            var curSelect = $('#modificationId')[0];
            var curOptions = curSelect.options;
            for (var i=0; i<curOptions.length; i++) {
              if (curOptions[i].value == 'loadingChanges') {
                curOptions[i] = null;
                break;
              }
            }

            if (parseInt(curOptions[curOptions.length-1].value) > 0) {
              curOptions[curOptions.length-1] = null; // selected change
            }

            var selectedIdx = curSelect.selectedIndex;
            var newSelect = $('#changesOptions select')[0];
            var hasChanges = newSelect.options.length > 0;
            for (i=0; i<newSelect.options.length; i++) {
              var opt = newSelect.options[i];
              curSelect.appendChild(new Option(opt.text, opt.value, opt.defaultSelected));
              if (selectedIdx <= 0 && opt.defaultSelected) {
                selectedIdx = curSelect.options.length - 1;
              }
            }

            if (selectedIdx > 0) {
              curSelect.selectedIndex = selectedIdx;
            }
            var controlId = BS.jQueryDropdown.namePrefix + 'modificationId',
              dropdownClass = 'list-wrapper' + controlId;

            var expanded = !$('.' + dropdownClass).hasClass('invisible');

            BS.jQueryDropdown('#modificationId').ufd("changeOptions");

            if (hasChanges) {
              var dropdownList = $('.' + dropdownClass).find('ul');

              <c:url var="changelog_url" value="/viewType.html?buildTypeId=${runBuildBean.buildType.externalId}&tab=buildTypeChangeLog"/>
              dropdownList.append('<li class="unfilterable">See <a href="${changelog_url}">Change Log</a> for older changes</li>');
            }

            if (expanded) {
              $('#' + controlId).trigger('click');
            }
          }
        });

        $('#modificationId').change(function() {
          BS.RunBuildDialog.enableSubmit();
          BS.RunBuildDialog.updateChangesContainer('revisionsContainer');
        });

        BS.RunBuildDialog.highlightSettingRevisions();
      })(jQuery);
    </script>
    </bs:refreshable>
  </div>
</authz:authorize>
