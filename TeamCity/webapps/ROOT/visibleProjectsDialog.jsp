<%@ include file="include-internal.jsp"

%><jsp:useBean id="visibleProjectsBean" type="jetbrains.buildServer.controllers.profile.VisibleProjectsBean" scope="request"

/><c:url value='/visibleProjects.html' var="actionUrl"
/><bs:visibleObjectsDialog actionUrl="${actionUrl}"
                           object="projects"
                           objectHumanReadable="projects"
                           jsDialog="BS.VisibleProjectsDialog"
                           visibleObjectBean="${visibleProjectsBean}"
                           rootProject="${visibleProjectsBean.rootProject}"
                           resetAction="${true}" resetButtonLabel="Reset order in selected projects"/>
