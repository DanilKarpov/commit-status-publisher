<%@ include file="include-internal.jsp"

%><jsp:useBean id="visibleBuildTypesBean" type="jetbrains.buildServer.controllers.profile.VisibleBuildTypesBean" scope="request"

/><c:url value='/visibleBuildTypes.html?projectId=${visibleBuildTypesBean.project.externalId}' var="actionUrl"
/><bs:visibleObjectsDialog actionUrl="${actionUrl}"
                           object="bt"
                           objectHumanReadable="build configurations"
                           jsDialog="BS.VisibleBuildTypesDialog"
                           visibleObjectBean="${visibleBuildTypesBean}"
                           resetAction="true"/>