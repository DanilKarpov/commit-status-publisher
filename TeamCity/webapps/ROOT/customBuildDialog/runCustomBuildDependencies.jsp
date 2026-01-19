<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="runBuildBean" type="jetbrains.buildServer.controllers.RunBuildBean" scope="request"/>
<jsp:useBean id="dependencies" type="jetbrains.buildServer.controllers.RunBuildDependencies" scope="request"/>
<jsp:useBean id="isPersonalPromotion" type="java.lang.Boolean" scope="request"/>
<c:set var="stateKeyParam" value="${util:urlEscape(param['stateKey'])}"/>
<c:url var="dialogUrl" value="/runCustomBuild.html?buildTypeId=${runBuildBean.buildType.externalId}&stateKey=${stateKeyParam}&customBuildDialog=true"/>

<c:if test="${dependencies.hasSnapshotDependencies or dependencies.hasArtifactDependencies}">
  <script type="text/javascript">
    BS.CustomBuildDependencies = {
      switchMode: function(event, dependentEvent) {
        if (!dependentEvent) {
          if (this.selectedIndex == 1) {
            $j('#dependencies-tab select.dependenciesSelect').each(
              function() { if (!this.disabled && this.options.length > 1 && this.options[1].value == '__rebuild__') { this.setSelected(1); $j(this).triggerHandler('change', [true]); } }
            );
          }
          if (this.selectedIndex == 2) {
            $j('#dependencies-tab select.dependenciesSelect').each(
              function() { if (!this.disabled && this.options[0].value == '') { this.setSelected(0); $j(this).triggerHandler('change', [true]); } }
            );
          }
          for (var i=0; i < this.options.length; i++) {
            if (this.selectedIndex != i) {
              $j('#rebuild_option_' + i).hide();
            } else {
              $j('#rebuild_option_' + i).show();
            }
          }
        }
      },

      resortDependencies: function(mode) {
        $j('#sortDependencies').show();
        BS.ajaxRequest('${dialogUrl}', {
          parameters: 'sortDependencies=' + mode,
          onSuccess: function() {
            $('dependenciesTable').refresh('sortDependencies');
          }
        })
      }
    }
  </script>
  <div id="dependencies-tab" style="display: none;" class="tabContent">
    <bs:refreshable containerId="dependenciesTable" pageUrl="${dialogUrl}">
      <table class="runnerFormTable">
        <tr>
          <td>
            <table style="width: 100%; padding-bottom: 6px">
              <tr>
                <td style="width: 28%; vertical-align: top">
                  <c:if test="${dependencies.hasSnapshotDependencies}">
                    <label for="rebuildDependenciesMode">Rebuild snapshot dependencies:</label>
                  </c:if>
                </td>
                <td stle="padding-left: 0.5em; vertical-align: top">
                  <c:if test="${dependencies.hasSnapshotDependencies}">
                    <forms:select name="rebuildDependenciesMode" style="width: 15em">
                      <forms:option value="">&lt;only selected&gt;</forms:option>
                      <forms:option value="all">&lt;all&gt;</forms:option>
                      <forms:option value="failed">&lt;all failed, failed to start and canceled&gt;</forms:option>
                    </forms:select>
                    <script type="text/javascript">
                      $j('#rebuildDependenciesMode')[0].onchange = BS.CustomBuildDependencies.switchMode;
                    </script>
                  </c:if>
                </td>
                <td>
                  <a style="float: right" href="#" onclick="$j('#dependencies-tab select.dependenciesSelect').each(
                    function() {
                      if (!this.disabled) {
                        this.setSelected(0); this._changedManually = null; BS.RunBuildDialog.highlightDependency(this, '');
                      }
                    });
                    if ($j('#rebuildDependenciesMode')[0]) {
                      $j('#rebuildDependenciesMode')[0].selectedIndex = 0; $j('#rebuildDependenciesMode')[0].onchange();
                    }">Reset all
                  </a>
                  <c:if test="${dependencies.hasArtifactDependencies}">
                  <span style="float: right; padding-right: 4px">
                    <forms:progressRing id="sortDependencies" style="float:none; display: none;" progressTitle="Re-sorting dependencies..."/>
                    <c:choose>
                      <c:when test="${dependencies.sortDependenciesMode eq 'BRANCH_THEN_DATE'}">
                        <a href="#" onclick="BS.CustomBuildDependencies.resortDependencies('DATE'); return false;">Sort dependencies by date</a> |
                      </c:when>
                      <c:otherwise>
                        <a href="#" onclick="BS.CustomBuildDependencies.resortDependencies('BRANCH_THEN_DATE'); return false;">Sort dependencies by branch, then by date</a> |
                      </c:otherwise>
                    </c:choose>
                  </span>
                  </c:if>
                </td>
              </tr>
              <tr>
                <td colspan="3">
                  <span class="smallNote" id="rebuild_option_1" style="display: none; width: auto;">Rebuild all snapshot dependencies, both direct and indirect.</span>
                  <span class="smallNote" id="rebuild_option_2" style="display: none; width: auto;">Rebuild failed, failed to start and canceled snapshot dependencies, both direct and indirect.</span>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td>
            <c:set value="${dependencies.rebuildDependenciesMap}" var="rebuildDepsMap"/>
            <c:set value="${dependencies.snapshotDependenciesWithoutArtifactDeps}" var="snapshotDepsWithoutArtifacts"/>
            <c:set value="${dependencies.artifactDependenciesSourceBuildTypes}" var="buildTypesMap"/>
            <c:set value="${dependencies.defaultArtifactDependencies}" var="artDeps"/>
            <c:set value="${dependencies.customArtifactDependenciesMap}" var="customDepsMap"/>
            <c:set value="${dependencies.lastBuilds}" var="lastBuilds"/>
            <table class="dependenciesList" style="width: 100%">
              <c:forEach items="${artDeps}" var="artDep" varStatus="pos">
                <c:set var="elemName" value="artifactDependency_${artDep.sourceBuildTypeId}"/>
                <c:set var="elemId" value="${elemName}_${pos.index}"/>
                <tr <c:if test="${customDepsMap[artDep.sourceBuildTypeId] != null}">class="modifiedParam"</c:if>>
                  <td style="width: 28%; vertical-align: top">
                    <c:set var="bt" value="${buildTypesMap[artDep.sourceBuildTypeId]}"/>
                    <label for="${elemId}"><c:choose>
                      <c:when test="${not empty bt}"><bs:buildTypeLinkFull buildType="${bt}"/></c:when>
                      <c:otherwise><em title="${not artDep.accessible ? 'You do not have enough permissions to access this configuration' : 'Build configuration does not exist'}">inaccessible build configuration</em></c:otherwise>
                    </c:choose></label>
                  </td>
                  <td style="padding-left: 0.5em; vertical-align: top">
                    <c:choose>
                      <c:when test="${not empty bt}">
                        <c:set var="customDepBuildId" value="0"/>
                        <c:set var="isCustomDepPersonal" value="false"/>
                        <c:if test="${not empty customDepsMap[artDep.sourceBuildTypeId]}"><c:set var="customDepBuildId" value="${customDepsMap[artDep.sourceBuildTypeId].buildId}"/></c:if>
                        <c:if test="${customDepBuildId != 0 && customDepsMap[artDep.sourceBuildTypeId].personal}"><c:set var="isCustomDepPersonal" value="true"/></c:if>
                        <forms:select name="${elemName}" id="${elemId}" style="width: 90%;" className="dependenciesSelect" enableFilter="true" disabled="${isCustomDepPersonal}">
                          <forms:option value="">auto (<c:out value="${artDep.revisionRule.description}"/>)</forms:option>
                          <c:if test="${not empty rebuildDepsMap[artDep.sourceBuildTypeId]}">
                            <forms:option value="__rebuild__">rebuild</forms:option>
                            <c:if test="${intprop:getBooleanOrTrue('teamcity.conditional.dependencies.enabled')}">
                              <forms:option value="__skip__">skip</forms:option>
                            </c:if>
                          </c:if>
                          <c:forEach items="${lastBuilds[bt]}" var="buildInfo">
                            <forms:option value="buildId:${buildInfo.buildId}" selected="${buildInfo.buildId eq customDepBuildId}">
                              <%@include file="_buildInfo.jspf"%>
                            </forms:option>
                          </c:forEach>
                        </forms:select>
                        <script type="text/javascript">
                          $j('#${elemId}').on('change', function(event, dependentEvent) {
                            BS.RunBuildDialog.highlightDependency(this, '');
                            if (!dependentEvent) {
                              // manual change
                              this._changedManually = true;

                              var that = this;
                              $j('#dependencies-tab select').each(
                                function() {
                                  if (that != this && this.name.indexOf('artifactDependency_${artDep.sourceBuildTypeId}_') != -1 && !this._changedManually) {
                                    this.setSelected(that.selectedIndex);
                                    $j(this).triggerHandler('change', [true]);
                                  }
                                }
                              );
                              <c:if test="${not empty rebuildDepsMap[artDep.sourceBuildTypeId]}">
                              if (this.selectedIndex != 1 && $j('#rebuildDependenciesMode')[0]) {
                                $j('#rebuildDependenciesMode')[0].selectedIndex = 0; // only selected
                                $j('#rebuildDependenciesMode')[0].onchange();
                              }
                              </c:if>
                            }
                          }.bind($j('#${elemId}')[0]));
                        </script>
                      </c:when>
                      <c:otherwise>
                        <c:choose>
                          <c:when test="${not artDep.accessible and customDepsMap.containsKey(artDep.sourceBuildTypeId) and customDepsMap[artDep.sourceBuildTypeId] == null}">
                            same as in reran build
                            <input type="hidden" name="${elemName}" value="__rerun__:${artDep.id}"/>
                          </c:when>
                          <c:otherwise>
                            auto (<c:out value="${artDep.revisionRule.description}"/>)
                            <input type="hidden" name="${elemName}" value=""/>
                          </c:otherwise>
                        </c:choose>
                      </c:otherwise>
                    </c:choose>
                    <bs:smallNote>
                      Artifacts paths:<br/>
                      <div style="margin-left: 1em;" class="mono"><bs:out value="${artDep.sourcePaths}"/></div>
                    </bs:smallNote>
                  </td>
                </tr>
              </c:forEach>
              <c:forEach items="${snapshotDepsWithoutArtifacts}" var="bt" varStatus="pos">
                <tr <c:if test="${not empty lastBuilds[bt]}">class="modifiedParam"</c:if>>
                  <td style="width: 28%; vertical-align: top">
                    <bs:buildTypeLinkFull buildType="${bt}"/>
                  </td>
                  <td style="padding-left: 0.5em; vertical-align: top">
                    <c:set var="elemName" value="snapshotDependency_${bt.buildTypeId}"/>
                    <c:set var="elemId" value="${elemName}_${pos.index}"/>
                    <forms:select style="width: 90%;" name="${elemName}" id="${elemId}" className="dependenciesSelect" enableFilter="true" disabled="${isPersonalPromotion && not empty lastBuilds[bt]}">
                      <forms:option value="">auto</forms:option>
                      <forms:option value="__rebuild__">rebuild</forms:option>
                      <c:if test="${intprop:getBooleanOrTrue('teamcity.conditional.dependencies.enabled')}">
                        <forms:option value="__skip__">skip</forms:option>
                      </c:if>
                      <c:forEach items="${lastBuilds[bt]}" var="buildInfo">
                        <forms:option value="buildId:${buildInfo.buildId}" selected="true"><%@include file="_buildInfo.jspf"%></forms:option>
                      </c:forEach>
                    </forms:select>
                    <script type="text/javascript">
                      $j('#${elemId}').on('change', function(event, dependentEvent) {
                        BS.RunBuildDialog.highlightDependency(this, '');
                        if (!dependentEvent) {
                          if (this.selectedIndex != 1 && $j('#rebuildDependenciesMode')[0]) {
                            $j('#rebuildDependenciesMode')[0].selectedIndex = 0; // only selected
                            $j('#rebuildDependenciesMode')[0].onchange();
                          }
                        }
                      }.bind($j('#${elemId}')[0]));
                    </script>
                    <bs:smallNote>snapshot dependency</bs:smallNote>
                  </td>
                </tr>
              </c:forEach>
            </table>
          </td>
        </tr>
      </table>
    </bs:refreshable>
  </div>
</c:if>