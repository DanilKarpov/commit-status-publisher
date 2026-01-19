<%@ include file="/include-internal.jsp"
%><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser"  scope="request"
/><jsp:useBean id="projectBean" type="jetbrains.buildServer.controllers.overview.OverviewProjectBean"  scope="request"
/><c:set var="project" value="${projectBean.project}"
/><c:set var="projectId" value="${project.projectId}"
/><c:set var="externalId" value="${project.externalId}"
/><c:set var="projectBuildTypes" value="${projectBean.buildTypes}"
/><c:set var="hiddenBuildTypes" value="${projectBean.hiddenBuildTypes}"
/><c:set var="projectStatusDetails" value="${projectBean.projectStatusDetails}"
/><c:set var="branchBean" value="${projectBean.branchBean}" scope="request"
/><div class="build ${!projectBean.overviewPage ? 'project-page' : 'overview-page'}" id="p_${projectId}"
  ><et:subscribeOnProjectEvents projectId="${projectId}">
  <jsp:attribute name="eventNames">
    BUILD_STARTED
    BUILD_CHANGES_LOADED
    BUILD_CHANGED_STATUS
    BUILD_FINISHED
    BUILD_INTERRUPTED
    BUILD_TYPE_ACTIVE_STATUS_CHANGED
    BUILD_TYPE_ADDED_TO_QUEUE
    BUILD_TYPE_REMOVED_FROM_QUEUE
    BUILD_TYPE_REGISTERED
    BUILD_TYPE_UNREGISTERED
    CHANGE_ADDED
    PROJECT_PERSISTED
    PROJECT_RESTORED
  </jsp:attribute>
  <jsp:attribute name="eventHandler">
    <c:set var="firstProjectInList" value="${projectBean.firstProject}"/>
    BS.Projects.updateProjectView('${projectId}', '${externalId}', ${firstProjectInList});
  </jsp:attribute>
</et:subscribeOnProjectEvents>
<et:subscribeOnProjectEvents projectId="${projectId}">
  <jsp:attribute name="eventNames">
    PROJECT_REMOVED
    PROJECT_ARCHIVED
    PROJECT_DEARCHIVED
  </jsp:attribute>
  <jsp:attribute name="eventHandler">
    BS.reload();
  </jsp:attribute>
</et:subscribeOnProjectEvents

>
  <%--@elvariable id="hasFilteredConfigurations" type="java.lang.Boolean"--%>
  <%--@elvariable id="runningAndQueuedBuilds" type="jetbrains.buildServer.controllers.RunningAndQueuedBuildsBean"--%>
  <%--@elvariable id="problemsSummary" type="java.util.Map"--%>
  <c:if test="${intprop:getBoolean('teamcity.ui.experimental.projectOverview.switchAvailable') && ufn:booleanPropertyValue(currentUser, 'teamcity.ui.experimental.projectOverview')}">
    <style type="text/css">
      .tableCaption table.runTable td.pendingMessage{
        text-align: left !important;
      }
      .tableCaption {
        border-top: none !important;
      }
    </style>
  </c:if>
  <c:set var="projectStatus" value="${projectBean.status}"/>

  <c:set var="id" value="ovr_${projectId}"
  /><c:set var="hiddenBuildTypesNumber" value="${not empty hiddenBuildTypes ? fn:length(hiddenBuildTypes) : 0}"
  /><c:set var="blockId" value="t_${id}"
  /><c:set var="project_collapsed" value='${(projectBean.overviewPage or not firstProjectInList) and util:isBlockHidden(pageContext.request, blockId, not firstProjectInList)}'/>
  <div class="projectHeader ${project_collapsed ? "" : "exp"}" id="ph_${projectId}">
   <table class="projectHeaderTable">
     <tr>
       <td class="projectName">
         <c:set var="projectName"><c:out value="${project.name}"/></c:set>
         <c:set var="canViewSettings" value="${
           afn:permissionGrantedForProject(project, 'VIEW_BUILD_CONFIGURATION_SETTINGS') ||
           afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"
         />
         <bs:projectPopup project="${project}" withSelf="true" withAdmin="${canViewSettings}">
           <bs:handle handleId="${id}" collapsed="${project_collapsed}"
                      imgTitle="${projectStatus.failed ? 'Project has failing build configurations. Click to expand / collapse details' :
                                projectStatus.successful ? 'Project is successful. Click to expand / collapse details' :
                                                            'Project does not have builds. Click to expand / collapse details'}"/>
           <bs:projectOrBuildTypeIcon type="project" failing="${projectStatus.failed}" successful="${projectStatus.successful}"/>
           <a href="<bs:projectUrl projectId='${externalId}'/>" title="Go to the &#34;${projectName}&#34; page">${projectName}</a>
         </bs:projectPopup>
         <c:if test="${not empty project.description}"><span class="projectDescription"><bs:out value="${project.description}" resolverContext="${project}"/></span></c:if>
         <c:if test="${project.archived}"><i class="archived_project">(archived)</i></c:if>
       </td>
       <td class="branches">
         <span class="branchContainer" id="branch_container_${id}" style="display:none; width: 168px;"></span>
             <c:if test="${not projectBean.overviewPage}">
               <script type="text/javascript">
                BS.Branch.registerProjectBranch("${externalId}", "<bs:escapeForJs text="${branchBean.userBranch}"/>");
               </script>
             </c:if>
             <c:if test="${projectBean.overviewPage && !project_collapsed}">
               <bs:_projectBranchSelector project="${project}" branchBean="${branchBean}" projectPaneId="#branch_container_${id}"
                                          isFirst="${firstProjectInList}"/>
             </c:if>
       </td>
       <td class="projectStatus err">
         <c:set var="errorsNum" value="${projectStatusDetails.errorsNumber}"/>
         <c:if test="${errorsNum > 0}">
           <c:set var="tooltip">${errorsNum} build configuration<bs:s val="${errorsNum}"/> with configuration problems or failed to start builds</c:set>
           <span <bs:tooltipAttrs text="${tooltip}"/> ><bs:buildStatusIcon type="red-sign"/>${errorsNum} error<bs:s val="${errorsNum}"/></span>
         </c:if>
       </td>
       <td class="projectStatus failing">
         <c:set var="failingNum" value="${projectStatusDetails.failingNumber}"/>
         <c:if test="${failingNum > 0}">
           <c:set var="tooltip">${failingNum} failing build configuration<bs:s val="${failingNum}"/></c:set>
           <span <bs:tooltipAttrs text="${tooltip}"/> >${failingNum} failing</span>
         </c:if>
       </td>
       <td class="projectStatus successful">
         <c:set var="successfulNum" value="${projectStatusDetails.successfulNumber}"/>
         <c:if test="${successfulNum > 0}">
           <c:set var="tooltip">${successfulNum} successful build configuration<bs:s val="${successfulNum}"/></c:set>
           <span <bs:tooltipAttrs text="${tooltip}"/> >${successfulNum} successful</span>
         </c:if>
       </td>
       <td class="hideProject">
         <authz:authorize allPermissions="CHANGE_OWN_PROFILE"
           ><jsp:attribute name="ifAccessGranted"
             ><c:if test="${!isSpecialUser}"
               ><bs:showBuildTypesPopup projectId="${project.externalId}"><c:choose
                 ><c:when test="${hiddenBuildTypesNumber > 0}">${hiddenBuildTypesNumber} hidden</c:when
                 ><c:otherwise>no hidden</c:otherwise
               ></c:choose></bs:showBuildTypesPopup
              ><a class="hideProject" href="#" onclick="return BS.Projects.hideProject('${projectId}')" title="Hide this project">&#xd7;</a>
             </c:if
           ></jsp:attribute
           ><jsp:attribute name="ifAccessDenied">&nbsp;</jsp:attribute
         ></authz:authorize>
       </td>
     </tr>
   </table>
  </div>

  <div id="btb${id}" style="${project_collapsed ? 'display:none' : ''}">
    <c:if test="${projectBean.projectEmpty}">
      <div class="tableCaption">
        <c:choose>
          <c:when test="${hiddenBuildTypesNumber > 0 || projectBean.buildTypesFilteredByHideSuccessful}">
            <p class="empty-project-text">All build configurations are hidden</p>
          </c:when>
          <c:otherwise>
            <p class="empty-project-text">No build configurations.
            <authz:authorize allPermissions="EDIT_PROJECT" projectId="${project.projectId}">
              <c:choose>
                <c:when test="${empty param['child_project'] and not project.readOnly and not project.rootProject}">
                  <div class="create-build-type-buttons"><admin:createBuildTypeButtons project="${project}" cameFromUrl="${pageUrl}"/></div>
                </c:when>
                <c:otherwise>
                  <admin:editProjectLink projectId="${project.externalId}">${project.readOnly ? 'View' : 'Edit'} project settings</admin:editProjectLink>
                </c:otherwise>
              </c:choose>
            </authz:authorize>
            </p>
          </c:otherwise>
        </c:choose>
      </div>
    </c:if>

    <c:set var="showAllSetting" value="shows_all_build_types_${project.projectId}"
    /><c:set var="shouldShowHideBuildTypeIcon" value="${projectBean.overviewPage}"
    /><l:displayCollapsibleBlock blocksType="${blockId}"
                                 id="btb${id}"
                                 collapsedByDefault="${not firstProjectInList}"
                                 alwaysShowBlock="${(!projectBean.overviewPage and firstProjectInList) or param['force_show_build_types']}"
      ><jsp:attribute name="content"
        ><jsp:useBean id="branchBean" type="jetbrains.buildServer.controllers.BranchBean" scope="request"
          /><c:if test="${projectBean.projectEmpty and projectBean.buildTypesFilteredByHideSuccessful}"
          ><c:set var="num" value="${fn:length(project.ownBuildTypes)}"/>
          <p><b>${num}</b> successful build configuration<bs:s val="${num}"/> are hidden.
          <a href="#" onclick="BS.User.setBooleanProperty('overview.hideSuccessful', false, {afterComplete:function(){BS.reload(true);}}); return false">Show</a></p>
        </c:if

        ><c:forEach var="buildType" items="${projectBuildTypes}"
          ><jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.BuildTypeEx"
            /><c:set var="buildTypeBranchBean" value="<%=branchBean.createIn(buildType)%>"
            /><jsp:useBean id="buildTypeBranchBean" type="jetbrains.buildServer.controllers.BuildTypeBranchBean"
            /><c:set var="branchExcluded" value="<%=buildType.isDefaultBranchExcluded() && buildTypeBranchBean.isDefaultBranch()%>"
            /><c:if test="${not branchExcluded}"
              ><bs:_buildTypeTable currentUser="${currentUser}"
               buildType="${buildType}"
               branchBean="${buildTypeBranchBean}"
               runningAndQueuedBuilds="${runningAndQueuedBuilds}"
               problemsCounters="${problemsSummary[buildType]}"
               shouldShowHideBuildTypeIcon="${shouldShowHideBuildTypeIcon}"
               overviewPage="${projectBean.overviewPage}"
            /></c:if></c:forEach
        ><c:if test="${not empty buildTypeBranchBean and not buildTypeBranchBean.allBranches}">
          <script type="text/javascript">
            BS.Branch.injectBranchParamToLinks($j("#p_${projectId}"), "${externalId}");
          </script>
        </c:if
      ><c:forEach var="childBean" items="${projectBean.children}"
        ><bs:changeRequest key="projectBean" value="${childBean}"
          ><jsp:include page="/projectBuildTypes.jsp"><jsp:param name="force_show_build_types" value=""/><jsp:param name="child_project" value="true"/></jsp:include></bs:changeRequest
        ></c:forEach
      ></jsp:attribute
    ></l:displayCollapsibleBlock>
  </div>

  <script>
    BS.stopObservingWhenDetached(document.getElementById('p_${projectId}'));
  </script>
  <c:if test="${projectBean.overviewPage or not firstProjectInList}"
    ><script type="text/javascript">
      <l:blockState blocksType="${blockId}"/>
      BS.CollapsableBlocks.registerBlock(new BS.ProjectBlock("t_", '${id}', '${externalId}', ${not firstProjectInList}));
    </script>
  </c:if><c:if test="${not branchBean.allBranches}"><script type="text/javascript">
  (function($) {
      BS.Branch.injectBranchParamToLinks($j("#p_${projectId} .projectHeader"), "${externalId}");
  })(jQuery);
</script></c:if>
</div>
